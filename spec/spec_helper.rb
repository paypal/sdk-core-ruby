require 'bundler/setup'

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
  end
end

Bundler.require :default, :test

require 'coveralls'
Coveralls.wear!

require 'logger'
PayPal::SDK.load('spec/config/paypal.yml', 'test')
PayPal::SDK.logger = Logger.new(STDERR)

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each {|f| require f }

RSpec.configure do |config|
  config.include SampleData
end
