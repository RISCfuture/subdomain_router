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
      expect(@controller.url_for('foo')).to eql('foo')
    end

    context "[given host]" do
      before :each do
        allow(@controller).to receive(:request).and_return(double('ActionDispatch::Request', host: 'test.host'))
      end

      it "should leave the domain untouched if :subdomain => nil" do
        expect(@controller.url_for(host: 'foo.bar')).to eql(host: 'foo.bar')
        expect(@controller.url_for(host: 'sd.foo.bar')).to eql(host: 'sd.foo.bar')
        expect(@controller.url_for(host: 'baz.bat.foo.bar')).to eql(host: 'baz.bat.foo.bar')
      end

      it "should replace the subdomain if :subdomain is given" do
        expect(@controller.url_for(host: 'foo.bar', subdomain: 'sd')).to eql(host: 'sd.foo.bar')
        expect(@controller.url_for(host: 'baz.foo.bar', subdomain: 'sd')).to eql(host: 'sd.foo.bar')
        expect(@controller.url_for(host: 'baz.bat.foo.bar', subdomain: 'sd')).to eql(host: 'sd.foo.bar')
      end

      it "should use the default subdomain if :subdomain is false" do
        expect(@controller.url_for(host: 'foo.bar', subdomain: false)).to eql(host: 'foo.bar')
        expect(@controller.url_for(host: 'baz.foo.bar', subdomain: false)).to eql(host: 'foo.bar')
        expect(@controller.url_for(host: 'baz.bat.foo.bar', subdomain: false)).to eql(host: 'foo.bar')
      end
    end

    context "[request host]" do
      it "should leave the domain untouched if :subdomain => nil" do
        allow(@controller).to receive(:request).and_return(double('ActionDispatch::Request', host: 'foo.bar'))
        expect(@controller.url_for(subdomain: nil)).to eql({})

        allow(@controller).to receive(:request).and_return(double('ActionDispatch::Request', host: 'sd.foo.bar'))
        expect(@controller.url_for(subdomain: nil)).to eql({})

        allow(@controller).to receive(:request).and_return(double('ActionDispatch::Request', host: 'baz.bat.foo.bar'))
        expect(@controller.url_for(subdomain: nil)).to eql({})
      end

      it "should replace the subdomain if :subdomain is given" do
        allow(@controller).to receive(:request).and_return(double('ActionDispatch::Request', host: 'foo.bar'))
        expect(@controller.url_for(subdomain: 'sd')).to eql(host: 'sd.foo.bar')

        allow(@controller).to receive(:request).and_return(double('ActionDispatch::Request', host: 'baz.foo.bar'))
        expect(@controller.url_for(subdomain: 'sd')).to eql(host: 'sd.foo.bar')

        allow(@controller).to receive(:request).and_return(double('ActionDispatch::Request', host: 'baz.bat.foo.bar'))
        expect(@controller.url_for(subdomain: 'sd')).to eql(host: 'sd.foo.bar')
      end

      it "should use the default subdomain if :subdomain is false" do
        allow(@controller).to receive(:request).and_return(double('ActionDispatch::Request', host: 'foo.bar'))
        expect(@controller.url_for(subdomain: false)).to eql(host: 'foo.bar')

        allow(@controller).to receive(:request).and_return(double('ActionDispatch::Request', host: 'baz.foo.bar'))
        expect(@controller.url_for(subdomain: false)).to eql(host: 'foo.bar')

        allow(@controller).to receive(:request).and_return(double('ActionDispatch::Request', host: 'baz.bat.foo.bar'))
        expect(@controller.url_for(subdomain: false)).to eql(host: 'foo.bar')
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
        expect { @mailer.url_for(controller: 'users', action: 'new', subdomain: nil) }.to raise_error(ArgumentError)
      end

      it "should replace the subdomain if :subdomain is given" do
        expect(@mailer.url_for(controller: 'users', action: 'new', subdomain: 'sd')).to eql('http://sd.test.host/users/new')
      end

      it "should use the default subdomain if :subdomain is false" do
        expect(@mailer.url_for(controller: 'users', action: 'new', subdomain: false)).to eql('http://test.host/users/new')
      end
    end
  end
end

describe SubdomainRouter::Constraint do
  describe ".matches?" do
    before :each do
      @env = {}
      @request = double('ActionDispatch::Request', env: @env)
    end

    it "should return false if there is more than one subdomain" do
      allow(@request).to receive(:subdomains).and_return(%w( foo bar ))
      expect(SubdomainRouter::Constraint.matches?(@request)).to eql(false)
    end

    it "should return false if there is no subdomain" do
      allow(@request).to receive(:subdomains).and_return([])
      expect(SubdomainRouter::Constraint.matches?(@request)).to eql(false)
    end

    it "should return false if the subdomain is equal to the default subdomain" do
      SubdomainRouter::Config.default_subdomain = 'www'
      allow(@request).to receive(:subdomains).and_return(%w( www ))
      expect(SubdomainRouter::Constraint.matches?(@request)).to eql(false)
    end

    it "should return false if the subdomain does not belong to any user" do
      allow(@request).to receive(:subdomains).and_return(%w( not-found ))
      expect(SubdomainRouter::Constraint.matches?(@request)).to eql(false)
    end

    it "should return true if the subdomain belongs to a user and save the user to the env" do
      SubdomainRouter::Config.subdomain_matcher = ->(subdomain, request) { subdomain == 'valid' }
      allow(@request).to receive(:subdomains).and_return([ 'valid' ])
      expect(SubdomainRouter::Constraint.matches?(@request)).to eql(true)
    end

    it "should downcase the subdomain" do
      SubdomainRouter::Config.subdomain_matcher = ->(subdomain, request) { subdomain == 'valid' }
      allow(@request).to receive(:subdomains).and_return([ 'VALID' ])
      expect(SubdomainRouter::Constraint.matches?(@request)).to eql(true)
    end
  end
end
