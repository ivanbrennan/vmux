require 'spec_helper'

describe "vmux" do
  let(:vmux_sessions) { [1,2,3].map { |i| "vmux-test-session-#{i}" }  }
  around(:each)       { |example| renew_tmux(vmux_sessions, &example) }

  describe ":VmuxPrimary" do
  end
end
