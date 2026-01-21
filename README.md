# JSONAPI::Resources

`JSONAPI::Resources`, or "JR", provides a framework for developing an API server that complies with the
[JSON:API](http://jsonapi.org/) specification.

Like JSON:API itself, JR's design is focused on the resources served by an API. JR needs little more than a definition
of your resources, including their attributes and relationships, to make your server compliant with JSON API.

JR is designed to work with Rails 5.1+, and provides custom routes, controllers, and serializers. JR's resources may be
backed by ActiveRecord models or by custom objects.

## Speee Fork

This is the [Speee](https://speee.jp/) fork of [jsonapi-resources](https://github.com/cerebris/jsonapi-resources).

### Goals

- **Modern Rails Support**: Enable compatibility with the latest Rails versions (7.1, 7.2, 8.0, 8.1+)
- **0.9.x Backward Compatibility**: Maintain compatibility with code written for jsonapi-resources 0.9.x

### Key Changes from Upstream

#### Rails Compatibility
- Full support for Rails 7.1, 7.2, 8.0, and 8.1
- Rack 3.0 compatibility fixes
- Rails 8.2 deprecation warning fixes

#### 0.9.x Backward Compatibility
- `result.resource` and `result.resources` accessors on operation results
- `apply_filters` method made public for custom filter implementations
- PORO (Plain Old Ruby Object) support in `find_fragments`

#### Bug Fixes
- MySQL compatibility fix for the `quote` method (uses database adapter)
- Ruby 2.6/2.7 compatibility for `Psych.unsafe_load`

#### Development
- Docker support for multi-version Rails testing
- Comprehensive CI matrix covering Ruby 2.6-3.4 and Rails 5.1-8.1
- SimpleCov integration for test coverage measurement

## Documentation

Full documentation can be found at [http://jsonapi-resources.com](http://jsonapi-resources.com), including the [v0.10 alpha Guide](http://jsonapi-resources.com/v0.10/guide/) specific to this version.

## Demo App

We have a simple demo app, called [Peeps](https://github.com/cerebris/peeps), available to show how JR is used.

## Client Libraries

JSON:API maintains a (non-verified) listing of [client libraries](http://jsonapi.org/implementations/#client-libraries)
which *should* be compatible with JSON:API compliant server implementations such as JR.

## Installation

### Using This Fork

To use this fork, add the following to your application's `Gemfile`:

```ruby
gem 'jsonapi-resources', github: 'speee/jsonapi-resources', tag: 'v26.1.1'
```

Then execute:

```bash
bundle install
```

You can find available tags at [https://github.com/speee/jsonapi-resources/tags](https://github.com/speee/jsonapi-resources/tags).

### Original (upstream)

To use the original jsonapi-resources gem from RubyGems, add it to your application's `Gemfile`:

```ruby
gem 'jsonapi-resources'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install jsonapi-resources
```

**For further usage see the [v0.10 alpha Guide](http://jsonapi-resources.com/v0.10/guide/)**

## Contributing

1. Submit an issue describing any new features you wish it add or the bug you intend to fix
1. Fork it ( https://github.com/speee/jsonapi-resources/fork )
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Run the full test suite (`rake test`)
1. Fix any failing tests
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create a new Pull Request

## Did you find a bug?

* **Ensure the bug was not already reported** by searching on GitHub under [Issues(upstream)](https://github.com/cerebris/jsonapi-resources/issues) or [Issues(speee)](https://github.com/speee/jsonapi-resources/issues).

* If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/speee/jsonapi-resources/issues/new).
Be sure to include a **title and clear description**, as much relevant information as possible,
and a **code sample** or an **executable test case** demonstrating the expected behavior that is not occurring.

* If possible, use the relevant bug report templates to create the issue.
Simply copy the content of the appropriate template into a .rb file, make the necessary changes to demonstrate the issue,
and **paste the content into the issue description or attach as a file**:

## License

Copyright 2014-2021 Cerebris Corporation. MIT License (see LICENSE for details).
