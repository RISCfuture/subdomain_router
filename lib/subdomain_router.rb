# Module for working with dynamic subdomain routing.

module SubdomainRouter

  # Controller mixin that adds subdomain management features.

  module Controller
    extend ActiveSupport::Concern

    included do
      helper_method(:url_for) if respond_to?(:helper_method)
    end

    # Adds to the `url_for` method the ability to route to different subdomains.
    # Thus, all URL generation (including smart route methods) gains the
    # `:subdomain` options.
    #
    # For more information, see the Rails documentation.
    #
    # @param [Hash] options Options for the URL.
    # @option options [String, nil, false] :subdomain The subdomain to route to.
    #   If `false`, uses the default subdomain (e.g., "www"). If `nil`, uses the
    #   current subdomain.
    # @return [String] The generated URL.
    # @raise [ArgumentError] If the `:subdomain` option is invalid.

    def url_for(options={})
      return super unless options.is_a?(Hash)

      case options[:subdomain]
        when nil
          options.delete :subdomain
          super options
        when false, String
          subdomain = options.delete(:subdomain) || Config.default_subdomain
          host = options[:host] || (respond_to?(:request) && request.host) || Config.domain
          host_parts = host.split('.').last(Config.tld_components + 1)
          host_parts.unshift subdomain
          host_parts.delete_if &:blank?
          super options.merge(host: host_parts.join('.'))
        else
          raise ArgumentError, ":subdomain must be nil, false, or a string"
      end
    end
  end

  # A routing constraint that restricts routes to only valid dynamic subdomains.
  #
  # @example
  #   get 'home' => 'accounts#show', constraint: SubdomainRouter::Constraint

  module Constraint

    # Determines if a given request has a custom user subdomain.
    #
    # @param [ActionDispatch::Request] request An HTTP request.
    # @return [true, false] Whether the request subdomain matches a known user
    #   subdomain.

    def matches?(request)
      return false unless request.subdomains.size == 1
      return false if request.subdomains.first == Config.default_subdomain
      return subdomain?(request)
    end
    module_function :matches?

    private

    def subdomain?(request)
      subdomain = request.subdomains.first.downcase
      Config.subdomain_matcher.(subdomain, request)
    end
    module_function :subdomain?
  end

  # Subdomain routing configuration object.

  Config = Struct.new(:default_subdomain, :domain, :tld_components, :subdomain_matcher).new
  Config.default_subdomain = Rails.env.test? ? '' : 'www'
  Config.domain = 'lvh.me' if Rails.env.development?
  Config.domain = 'test.host' if Rails.env.test?
  Config.tld_components = 1
  Config.subdomain_matcher = ->(subdomain, request) { false }
end
