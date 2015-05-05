require 'spec_helper'

describe "vmux" do
  let(:vmux_sessions) { [1,2,3].map { |i| "vmux-test-session-#{i}" }  }
  around(:each)       { |example| renew_tmux(vmux_sessions, &example) }

  describe ":VmuxPrimary" do
    it "sets primary target" do
      vim.feedkeys ":VmuxPrimary\\<CR>"

      desired_primary = "vmux-test-session-1:0.0"
      vim.feedkeys "#{desired_primary}\\<CR>"

      expect(vim.echo "g:vmux_primary").to eq(desired_primary)
    end
  end

  describe ":VmuxSecondary" do
    it "sets secondary target" do
      vim.feedkeys ":VmuxSecondary\\<CR>"

      desired_secondary = "vmux-test-session-2:0.0"
      vim.feedkeys "#{desired_secondary}\\<CR>"

      expect(vim.echo "g:vmux_secondary").to eq(desired_secondary)
    end
  end
end
