require 'spec_helper'

describe "vmux" do
  let(:vmux_sessions) { [1,2,3].map { |i| "vmux-test-session-#{i}" }  }
  around(:each)       { |example| renew_tmux(vmux_sessions, &example) }

  it "initializes primary target" do
    expect(vim.echo "g:vmux_primary").to eq("")
  end
  it "initializes secondary target" do
    expect(vim.echo "g:vmux_secondary").to eq("")
  end
  it "initializes auto-spawn option" do
    expect(vim.echo "g:vmux_auto_spawn").to eq("")
  end

  it "doesn't clobber a previously set target" do
    eager_target = "my-special-session"
    Vimrunner.start do |clean_vim|
      clean_vim.command "let g:vmux_primary = '#{eager_target}'"

      clean_vim.add_plugin(ROOT, 'plugin/vmux.vim')

      expect(clean_vim.echo "g:vmux_primary").to eq(eager_target)
    end
  end

  describe ":VmuxPrimary" do
    it "sets primary target" do
      vim.feedkeys ":VmuxPrimary\\<CR>"

      target = "vmux-test-session-1:0.0"
      vim.feedkeys "#{target}\\<CR>"

      expect(vim.echo "g:vmux_primary").to eq(target)
    end
  end

  describe ":VmuxSecondary" do
    it "sets secondary target" do
      vim.feedkeys ":VmuxSecondary\\<CR>"

      target = "vmux-test-session-2:0.0"
      vim.feedkeys "#{target}\\<CR>"

      expect(vim.echo "g:vmux_secondary").to eq(target)
    end
  end

  describe "prompting for target" do
    before(:each) { vim.feedkeys ":VmuxPrimary\\<CR>" }

    it "prefills current target" do
      vim.feedkeys "add\\<CR>"

      vim.feedkeys ":VmuxPrimary\\<CR>"
      vim.feedkeys "ed\\<CR>"

      expect(vim.echo "g:vmux_primary").to eq("added")
    end

    describe "tab completion" do
      context "with partial session-name" do
        before(:each) { vim.feedkeys "vmux-te" }

        it "completes the session-name" do
          vim.command 'call feedkeys("\<Tab>\<CR>", "t")'
          expect(vim.echo "g:vmux_primary").to eq("vmux-test-session-1")
        end

        it "cycles through matching sessions" do
          vim.command 'call feedkeys("\<Tab>\<Tab>\<CR>", "t")'
          expect(vim.echo "g:vmux_primary").to eq("vmux-test-session-2")
        end
      end

      context "with 'session-name:'" do
        before(:each) { vim.feedkeys "vmux-test-session-1:" }

        it "completes window-index" do
          vim.command 'call feedkeys("\<Tab>\<CR>", "t")'
          expect(vim.echo "g:vmux_primary").to eq("vmux-test-session-1:0")
        end

        it "cycles through that session's matching windows" do
          [11, 12].each { |windex| new_window("vmux-test-session-1", windex) }
          [10, 11].each { |windex| new_window("vmux-test-session-2", windex) }

          vim.command 'call feedkeys("1\<Tab>\<Tab>\<CR>", "t")'

          expect(vim.echo "g:vmux_primary").to eq("vmux-test-session-1:12")
        end
      end

      context "with 'session-name:window-index.'" do
        before(:each) { vim.feedkeys "vmux-test-session-2:0." }

        it "completes pane-index" do
          vim.command 'call feedkeys("\<Tab>\<CR>", "t")'
          expect(vim.echo "g:vmux_primary").to eq("vmux-test-session-2:0.0")
        end

        it "cycles through that window's matching panes" do
          2.times { split_window("vmux-test-session-2", 0, 'h') }

          vim.command 'call feedkeys("\<Tab>\<Tab>\<Tab>\<CR>", "t")'

          expect(vim.echo "g:vmux_primary").to eq("vmux-test-session-2:0.2")
        end
      end

      context "with no available tmux server" do
        it "doesn't tab complete" do
          if list_sessions.sort == vmux_sessions.sort
            kill_server
          else
            raise "Please shut down tmux before running this test."
          end

          vim.command 'call feedkeys("\<Tab>something\<CR>", "t")'

          expect(vim.echo "g:vmux_primary").to eq("something")
        end
      end
    end
  end

  describe "opening target" do
    before(:each) do
      [1, 2].each { |windex| new_window("vmux-test-session-1", windex) }
    end

    context "with an existing pane targeted" do
      before(:each) do
        vim.feedkeys ":VmuxPrimary\\<CR>"
        vim.feedkeys "vmux-test-session-1:1.0\\<CR>"
      end

      it "selects targeted window" do
        expect{ vim.command "VmuxOpenPrimary" }.to change{
          window_index("vmux-test-session-1")
        }.to("1")
      end

      context "and targeting Vim's own session" do
        it "doesn't switch away from the active window"
      end

      it "doesn't adjust target setting" do
        split_window("vmux-test-session-1", "1")
        select_pane("vmux-test-session-1", "1", "1")

        expect{ vim.command "VmuxOpenPrimary" }.not_to change{
          vim.echo "g:vmux_primary"
        }
      end
    end

    context "with an existing window targeted" do
      before(:each) do
        vim.feedkeys ":VmuxSecondary\\<CR>"
        vim.feedkeys "vmux-test-session-1:1\\<CR>"
      end

      context "and auto-spawn off" do
        it "selects targeted window" do
          expect{ vim.command "VmuxOpenSecondary" }.to change{
            window_index("vmux-test-session-1")
          }.to("1")
        end

        context "and targeting Vim's own session" do
          it "doesn't switch away from the active window"
        end

        it "uses targeted window's active pane" do
          expect{ vim.command "VmuxOpenSecondary" }.not_to change{
            pane_index("vmux-test-session-1", "1")
          }
        end

        it "doesn't generate an error" do
          vim.command "VmuxOpenSecondary"
          expect(vim.echo "v:errmsg").to eq("")
        end

        it "adjusts target to point at the active pane" do
          2.times { split_window("vmux-test-session-1", "1") }

          expect{ vim.command "VmuxOpenSecondary" }.to change{
            vim.echo "g:vmux_secondary"
          }.from("vmux-test-session-1:1").to("vmux-test-session-1:1.2")
        end
      end
    end

    context "with an existing session targeted" do
      before(:each) do
        vim.feedkeys ":VmuxPrimary\\<CR>"
        vim.feedkeys "vmux-test-session-1\\<CR>"
      end

      context "and auto-spawn off" do
        it "uses targeted session's active window" do
          expect{ vim.command "VmuxOpenPrimary" }.not_to change{
            window_index("vmux-test-session-1")
          }.from("2")
        end

        it "uses active window's active pane" do
          expect{ vim.command "VmuxOpenPrimary" }.not_to change{
            pane_index("vmux-test-session-1", "2")
          }
        end

        it "doesn't generate an error" do
          vim.command "VmuxOpenPrimary"
          expect(vim.echo "v:errmsg").to eq("")
        end

        it "adjusts target to point at the active window's active pane" do
          2.times { split_window("vmux-test-session-1", "2") }

          expect{ vim.command "VmuxOpenPrimary" }.to change{
            vim.echo "g:vmux_primary"
          }.from("vmux-test-session-1").to("vmux-test-session-1:2.2")
        end
      end
    end

    context "with a non-existant target" do
      it "shows an error message" do
        vim.feedkeys ":VmuxPrimary\\<CR>"
        vim.feedkeys "vmux-test-session-1:9.0\\<CR>"

        vim.command "VmuxOpenPrimary"

        expect(vim.echo("v:errmsg")).to eq(
          "vmux: window not found: vmux-test-session-1:9"
        )
      end
    end

    context "with no target set" do
      it "prompts for a target" do
        expect{
          vim.feedkeys ":VmuxOpenSecondary\\<CR>"
          vim.feedkeys "vmux-test-session-1:0.0\\<CR>"
        }.to change{
          vim.echo "g:vmux_secondary"
        }.from("").to("vmux-test-session-1:0.0")
      end
    end
  end

  describe ":VmuxSendPrimary" do
    before(:each) { vim.feedkeys ":VmuxPrimary\\<CR>" }

    it "sends command to target" do
      target_pane = "vmux-test-session-1:0.0"
      vim.feedkeys "#{target_pane}\\<CR>"

      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      vim.command "VmuxSendPrimary \"echo '#{timestamp}'\""
      pane_contents = capture_pane(target_pane)

      expect(pane_contents).to match(/echo '#{timestamp}'\n#{timestamp}/)
    end

    context "with a non-existant target" do
      it "shows an error message" do
        vim.feedkeys "vmux-test-session-1:9.0\\<CR>"

        vim.command "VmuxSendPrimary \"echo 'hi'\""

        expect(vim.echo("v:errmsg")).to eq(
          "vmux: window not found: vmux-test-session-1:9"
        )
      end
    end
  end
end
