require 'vimrunner'
require 'vimrunner/rspec'
require 'support/tmux'

include Tmux

ROOT = File.expand_path('../..', __FILE__)

Vimrunner::RSpec.configure do |config|
  config.reuse_server = false

  config.start_vim do
    vim = Vimrunner.start
    vim.add_plugin(ROOT, 'plugin/vmux.vim')
    vim
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.warnings = true

  config.order = :random
end

def renew_tmux(session_names, &block)
  session_names.each { |name| new_session(name) }
  yield
  session_names.each { |name| kill_running_session(name) }
end

def kill_running_session(name)
  kill_session(name)
rescue RuntimeError => e
  raise e unless e.message =~ /^failed to connect to server: Connection refused$/
end
