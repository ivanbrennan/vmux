require 'vimrunner'
require 'vimrunner/rspec'

ROOT = File.expand_path('../..', __FILE__)

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  config.start_vim do
    vim = Vimrunner.start
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

