# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "subdomain_router"
  gem.homepage = "http://github.com/RISCfuture/subdomain_router"
  gem.license = "MIT"
  gem.summary = %Q{Use dynamic subdomains in your Rails website}
  gem.description = %Q{This adds a routing constraint and controller methods to allow dynamic subdomain-based routing.}
  gem.email = "gemcutter@timothymorgan.info"
  gem.authors = ["Tim Morgan"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task default: :spec

require 'yard'
YARD::Rake::YardocTask.new('doc') do |doc|
  doc.options << '-m' << 'markdown' << '-M' << 'redcarpet'
  doc.options << '--protected' << '--no-private'
  doc.options << '-r' << 'README.md'
  doc.options << '-o' << 'doc'
  doc.options << '--title' << 'Subdomain Router Documentation'

  doc.files = %w( lib/**/* README.md )
end
