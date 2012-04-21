require 'spec_helper'

class UrlForController < ActionController::Metal
  include SubdomainRouter::Controller
end

class UrlForMailer
  include SubdomainRouter::Controller
end

describe SubdomainRouter::Controller do
  before :all do
    @controller = UrlForController.new
  end

  describe "#url_for" do
    it "should call the superclass unless a hash is given" do
      @controller.url_for('foo').should eql('foo')
    end

    context "[given host]" do
      before :each do
        @controller.stub!(:request).and_return(mock('ActionDispatch::Request', host: 'test.host'))
      end

      it "should leave the domain untouched if :subdomain => nil" do
        @controller.url_for(host: 'foo.bar').should eql(host: 'foo.bar')
        @controller.url_for(host: 'sd.foo.bar').should eql(host: 'sd.foo.bar')
        @controller.url_for(host: 'baz.bat.foo.bar').should eql(host: 'baz.bat.foo.bar')
      end

      it "should replace the subdomain if :subdomain is given" do
        @controller.url_for(host: 'foo.bar', subdomain: 'sd').should eql(host: 'sd.foo.bar')
        @controller.url_for(host: 'baz.foo.bar', subdomain: 'sd').should eql(host: 'sd.foo.bar')
        @controller.url_for(host: 'baz.bat.foo.bar', subdomain: 'sd').should eql(host: 'sd.foo.bar')
      end

      it "should use the default subdomain if :subdomain is false" do
        @controller.url_for(host: 'foo.bar', subdomain: false).should eql(host: 'foo.bar')
        @controller.url_for(host: 'baz.foo.bar', subdomain: false).should eql(host: 'foo.bar')
        @controller.url_for(host: 'baz.bat.foo.bar', subdomain: false).should eql(host: 'foo.bar')
      end
    end

    context "[request host]" do
      it "should leave the domain untouched if :subdomain => nil" do
        @controller.stub!(:request).and_return(mock('ActionDispatch::Request', host: 'foo.bar'))
        @controller.url_for(subdomain: nil).should eql({})

        @controller.stub!(:request).and_return(mock('ActionDispatch::Request', host: 'sd.foo.bar'))
        @controller.url_for(subdomain: nil).should eql({})

        @controller.stub!(:request).and_return(mock('ActionDispatch::Request', host: 'baz.bat.foo.bar'))
        @controller.url_for(subdomain: nil).should eql({})
      end

      it "should replace the subdomain if :subdomain is given" do
        @controller.stub!(:request).and_return(mock('ActionDispatch::Request', host: 'foo.bar'))
        @controller.url_for(subdomain: 'sd').should eql(host: 'sd.foo.bar')

        @controller.stub!(:request).and_return(mock('ActionDispatch::Request', host: 'baz.foo.bar'))
        @controller.url_for(subdomain: 'sd').should eql(host: 'sd.foo.bar')

        @controller.stub!(:request).and_return(mock('ActionDispatch::Request', host: 'baz.bat.foo.bar'))
        @controller.url_for(subdomain: 'sd').should eql(host: 'sd.foo.bar')
      end

      it "should use the default subdomain if :subdomain is false" do
        @controller.stub!(:request).and_return(mock('ActionDispatch::Request', host: 'foo.bar'))
        @controller.url_for(subdomain: false).should eql(host: 'foo.bar')

        @controller.stub!(:request).and_return(mock('ActionDispatch::Request', host: 'baz.foo.bar'))
        @controller.url_for(subdomain: false).should eql(host: 'foo.bar')

        @controller.stub!(:request).and_return(mock('ActionDispatch::Request', host: 'baz.bat.foo.bar'))
        @controller.url_for(subdomain: false).should eql(host: 'foo.bar')
      end
    end

    context "[no host]" do
      before :all do
        @mailer = UrlForMailer.new
      end

      before :each do
        pending "Need to find a way to test this without building up a whole Rails app"
      end
      
      it "should leave the domain untouched if :subdomain => nil" do
        # no host provided = exception
        -> { @mailer.url_for(controller: 'users', action: 'new', subdomain: nil) }.should raise_error(ArgumentError)
      end

      it "should replace the subdomain if :subdomain is given" do
        @mailer.url_for(controller: 'users', action: 'new', subdomain: 'sd').should eql('http://sd.test.host/users/new')
      end

      it "should use the default subdomain if :subdomain is false" do
        @mailer.url_for(controller: 'users', action: 'new', subdomain: false).should eql('http://test.host/users/new')
      end
    end
  end
end

describe SubdomainRouter::Constraint do
  describe ".matches?" do
    before :each do
      @env = {}
      @request = mock('ActionDispatch::Request', env: @env)
    end

    it "should return false if there is more than one subdomain" do
      @request.stub!(:subdomains).and_return(%w( foo bar ))
      SubdomainRouter::Constraint.matches?(@request).should be_false
    end

    it "should return false if there is no subdomain" do
      @request.stub!(:subdomains).and_return([])
      SubdomainRouter::Constraint.matches?(@request).should be_false
    end

    it "should return false if the subdomain is equal to the default subdomain" do
      SubdomainRouter::Config.default_subdomain = 'www'
      @request.stub!(:subdomains).and_return(%w( www ))
      SubdomainRouter::Constraint.matches?(@request).should be_false
    end

    it "should return false if the subdomain does not belong to any user" do
      @request.stub!(:subdomains).and_return(%w( not-found ))
      SubdomainRouter::Constraint.matches?(@request).should be_false
    end

    it "should return true if the subdomain belongs to a user and save the user to the env" do
      SubdomainRouter::Config.subdomain_matcher = ->(subdomain, request) { subdomain == 'valid' }
      @request.stub!(:subdomains).and_return([ 'valid' ])
      SubdomainRouter::Constraint.matches?(@request).should be_true
    end

    it "should downcase the subdomain" do
      SubdomainRouter::Config.subdomain_matcher = ->(subdomain, request) { subdomain == 'valid' }
      @request.stub!(:subdomains).and_return([ 'VALID' ])
      SubdomainRouter::Constraint.matches?(@request).should be_true
    end
  end
end
