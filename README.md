Subdomain Router
================

A Ruby on Rails addition that adds dynamic subdomain routing to your web app.

|             |                                 |
|:------------|:--------------------------------|
| **Author**  | Tim Morgan                      |
| **Version** | 1.0 (Apr 20, 2012)              |
| **License** | Released under the MIT license. |

About
-----

This gem consists of two components: A routing constraint that can be used in
your `routes.rb` file to limit certain endpoints to dynamic subdomains (or vice
versa), and a monkey-patch to the `url_for` method that allows it to
intelligently generate URLs with subdomains.

The most common use case for this is if you have each of your users choose a
subdomain when they sign up, and then you route to different user accounts based
on their subdomain. (Think Heroku for example.)

Sorry about the monkey-patching by the way. :( You should probably inspect the
patch closely if you are using any other `url_for` hooks.

### Testing multiple subdomains in development

Typically in development you access your website by going to
"http://localhost:3000" (or perhaps "http://0.0.0.0:3000"). Neither of these
URLs is compatible with subdomains, however.

Fortunately there exists an easy solution that requires no changes to your
`/etc/hosts` file. The domain "lvh.me" points to 127.0.0.1, so by going to
"http://lvh.me:3000", you can access your local Rails instance. And it works
with subdomains: "http://custom.lvh.me:3000" will work just as well.

Installation
------------

### Gem installation

To use this gem, add to your Gemfile:

```` ruby
gem 'subdomain_router'
````

### Configuration

You will need to configure SubdomainRouter before you can use it. The
configuration code can be placed anywhere you feel is appropriate
(`config/application.rb`, a file in `config/initializers`, etc.) as long as it
runs when your web app starts up.

```` ruby
SubdomainRouter::Config.default_subdomain = 'www'
SubdomainRouter::Config.domain = 'mywebsite.com'
SubdomainRouter::Config.tld_components = 1
SubdomainRouter::Config.subdomain_matcher = ->(subdomain, request) { ... }
````

The configuration options are described below.

| Option              | Description                                                                                                                                                                                                        |
|:--------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `default_subdomain` | The subdomain to use when no dynamic subdomain is specified. This is the subdomain people would use when visiting your site for the first time (default "www" and "" for test.)                                    |
| `domain`            | The domain name. In development, it is by default `lvh.me` (see the _About_ section). In test, it is by default `test.host`. In production, it should be the domain name of your site.                             |
| `tld_components`    | The number of components in the TLD. If you have a `.com` website, this is 1. If you have a `.co.uk` website, it would be 2. In development and test, it should be 1 (default 1).                                  |
| `subdomain_matcher` | A `Proc` that takes a subdomain (as a `String`) and an `ActionDispatch::Request` object, and returns `true` if it is a valid dynamic subdomain, or `false` otherwise. A response of `false` would result in a 404. |

So as you can see, sensible defaults are provided for most options. At a
minimum, you need to set `subdomain_matcher` in all environments and `domain` in
production.

These configuration variables are shared by some others in Rails. For DRY
purposes, you can reuse the configuration values:

```` ruby
Rails.application.config.action_dispatch.tld_length = SubdomainRouter::Config.tld_components

# if you use cookies
Rails.application.config.session_store :cookie_store, domain: ".#{SubdomainRouter::Config.domain}", expire_after: 2.weeks, key: '_mysite_session'
````

### Code additions

In your `ApplicationController`, add the following:

```` ruby
include SubdomainRouter::Controller
````

In your routes file, group all of the routes you _do_ want to be accessible from
dynamic subdomains into a block like so:

```` ruby
constraints SubdomainRouter::Constraint do
  # [...]
end
````

Then group all of the routes you want accessible from the default subdomain into
a similar block:

```` ruby
constraints(subdomain: SubdomainRouter::Config.default_subdomain) do
  # [...]
end
````

This should be all you need. See the next section to learn how to use the
monkey-patched `url_for`.

Usage
-----

Aside from implementing the `subdomain_matcher` proc above, the only other thing
you will need to is provide subdomain information to all of your links. Since
`url_for` powers the URL methods (e.g., `posts_url`), the following information
applies to them equally.

For every call to `link_to` or `url_for` in your views, you will need to think
about how the link will work with subdomains. There are three possibilities:

* **Leave the subdomain untouched.** A link to `/bar` at `www.foo.com` will go
  to `www.foo.com/bar`. A link to `/bar` at `custom.foo.com` will go to
  `custom.foo.com/bar`.
* **Go to the default subdomain.** A link to `/bar` at `www.foo.com` will go to
  `www.foo.com/bar`. A link to `/bar` at `custom.foo.com` will go to
  `www.foo.com/bar`.
* **Go to a specific subdomain.** A link to `/bar` at `www.foo.com` will go to
  `custom.foo.com/bar`. A link to `/bar` at `another.foo.com` will go to
  `custom.foo.com/bar`.

So, if you want to **leave the subdomain untouched**, either omit the
`:subdomain` option from your call to `url_for`, or set it to `nil`:

```` ruby
url_for(controller: 'posts', action: 'index') # implied subdomain: nil
posts_url(subdomain: nil) # explicitly specifying
````

If you want to **go to the default subdomain**, set the `:subdomain` option to
`false`:

```` ruby
url_for(controller: 'testimonials', action: 'index', subdomain: false)
testimonials_url(subdomain: false)
````

If you want to **go to a specific subdomain**, specify it using the `:subdomain`
option:

```` ruby
url_for(controller: 'profile', action: 'show', subdomain: user.subdomain)
profile_url(subdomain: user.subdomain)
````

See {SubdomainRouter::Controller#url_for} for more.
