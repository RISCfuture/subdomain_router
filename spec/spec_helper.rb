$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bundler'
Bundler.require :development
Bundler.require
require 'action_controller'
require 'subdomain_router'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

SubdomainRouter::Config.default_subdomain = ''
SubdomainRouter::Config.tld_components = 1
SubdomainRouter::Config.domain = 'test.host'

RSpec.configure do |config|
  
end
