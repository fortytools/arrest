require 'simplecov'
SimpleCov.start

require 'rspec'
require 'rr'
require 'rack'

require 'arrest'

Dir["#{File.dirname(__FILE__)}/../spec/support/**/*.rb"].each {|f| require f}

Arrest::Source.source = nil

RSpec.configure do |config|
  config.mock_with :rr
  config.before(:each) do
    Arrest::MemSource.class_variable_set('@@data', {})
  end
end
