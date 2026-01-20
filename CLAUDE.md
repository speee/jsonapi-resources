# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`jsonapi-resources` (JR) is a Ruby gem that provides a framework for developing JSON:API compliant API servers in Rails. It's resource-centric, requiring mainly resource definitions (attributes, relationships) to achieve full JSON:API compliance.

**Supported Rails Versions:**
- Rails 6.1.7.10 ✅
- Rails 7.0.10 ✅
- Rails 7.1+ (in progress)
- Rails 8.0+ (in progress)

## Development Commands

### Testing
```bash
# Run full test suite
rake test

# Run single test file
ruby -I test test/unit/resource/resource_test.rb

# Run single test case
ruby -I test test/unit/resource/resource_test.rb -n test_method_name

# Run with coverage
COVERAGE=true bundle exec rake test

# Test specific Rails version
export RAILS_VERSION=6.1.1; bundle update; bundle exec rake test

# Run with specific seed for reproducibility
export RAILS_VERSION=6.1.1; bundle update; bundle exec rake TESTOPTS="--seed=39333" test

# Run benchmarks
rake test:benchmark

# Run with coverage measurement
COVERAGE=true bundle exec rake test

# View coverage report (after running with COVERAGE=true)
open coverage/index.html  # macOS
xdg-open coverage/index.html  # Linux
```

Coverage reports are generated using SimpleCov and saved to the `coverage/` directory. The configuration includes:
- Grouped coverage by component (Controllers, Resources, Serializers, etc.)
- Branch coverage tracking (Ruby 2.5+)
- Both HTML and console output formats
- Automatic exclusion of test files

### Docker Testing

The project includes Docker support for testing across multiple Rails versions:

```bash
# Test with specific Rails version
docker-compose run rails-6.1   # Rails 6.1.7.10
docker-compose run rails-7.0   # Rails 7.0.10
docker-compose run rails-7.1   # Rails 7.1.6
docker-compose run rails-7.2   # Rails 7.2.3
docker-compose run rails-8.0   # Rails 8.0.4
docker-compose run rails-8.1   # Rails 8.1.1

# Interactive shell with specific Rails version
docker-compose run shell
RAILS_VERSION=7.0.10 docker-compose run shell

# Run tests in interactive shell
docker-compose run shell
# Inside container:
bundle update
bundle exec rake test

# Run with coverage in Docker
docker-compose run -e COVERAGE=true rails-6.1
# Or in interactive shell:
docker-compose run shell
# Inside container:
COVERAGE=true bundle exec rake test

# Build/rebuild images
docker-compose build

# Clean up
docker-compose down -v  # Remove containers and volumes
```

Docker configuration files:
- `Dockerfile` - Container image definition (Ruby 3.2 + dependencies)
- `docker-compose.yml` - Service definitions for each Rails version
- `.dockerignore` - Files excluded from Docker context

### Database Setup
Tests use SQLite by default. The database is configured via `ENV['DATABASE_URL']` (defaults to `sqlite3:test_db`). DatabaseCleaner handles cleanup between tests.

## Architecture

### Core Request Flow

The library follows a layered architecture:

```
HTTP Request → ResourceController → Request → Operation → Processor → Resource → ActiveRecord Model
                                                                    ↓
HTTP Response ← ResponseDocument ← Serializer ← OperationResult ← ResourceSet
```

**Key layers:**

1. **ResourceController** (`ActsAsResourceController` mixin): Handles HTTP lifecycle, verifies headers (`application/vnd.api+json`), delegates to Request
2. **Request**: Parses filters, sorts, includes, pagination, sparse fieldsets; creates Operation objects
3. **Operation**: Discrete units of work (find, show, create_resource, etc.); delegates to Processor
4. **Processor**: Executes operations, calls Resource methods, returns OperationResults
5. **Resource**: Defines API resources with attributes, relationships, filters, sorts; bridges to ActiveRecord
6. **ResourceSet**: Collection of ResourceFragments populated from database (with optional caching)
7. **Serializer**: Converts ResourceSets to JSON:API format (primary data + included)

### Resource Hierarchy

Three-tier inheritance provides flexibility:

- **BasicResource**: Pure Ruby, no ActiveRecord dependency
- **ActiveRelationResource**: Adds ActiveRecord query building via `records()`, filtering, sorting, pagination
- **Resource**: Default entry point (includes `root_resource` designation)

Resources define the API surface:

```ruby
class ArticleResource < JSONAPI::Resource
  attributes :title, :body
  has_one :author
  has_many :comments

  filter :title, apply: ->(records, value, _options) {
    records.where(title: value)
  }
  sort :created_at
end
```

### JoinManager

The `JoinManager` (in `lib/jsonapi/active_relation/join_manager.rb`) is critical for performance. It:

- Consolidates JOIN requirements from relationships, filters, and sorts
- Tracks table aliases to prevent collisions
- Builds optimized queries with minimal joins
- Supports LEFT JOINs via adapters

When working with complex filters or sorts that require joins, understand JoinManager's role in query construction.

### Fragment-Based Architecture

Rather than eagerly loading full ActiveRecord models, JR uses:

- **ResourceFragment**: Lightweight data holder (identity + cache_field + partial attributes)
- **ResourceTree**: Hierarchical structure during query phase (mirrors included relationships)
- **ResourceSet**: Flattened collection for serialization

This enables efficient caching and avoids N+1 queries. The `ResourceSet.populate!` method checks cache, fetches missing resources, and updates cache.

### Caching Strategy

Fragment caching operates at the resource level:

- Cache key: resource type + id + cache_field hash + serializer config + context
- Supports any `ActiveSupport::Cache` store
- Configured via `CachedResponseFragment`
- Multi-read/write for efficiency

Cache is invalidated when the `cache_field` (typically `updated_at`) changes.

### Configuration

Global configuration in `JSONAPI.configure`:

```ruby
JSONAPI.configure do |config|
  config.json_key_format = :dasherized_key  # or :camelized_key, :underscored_key
  config.route_format = :dasherized_route
  config.resource_key_type = :integer  # or :uuid, :string
  config.allow_sort = true
  config.allow_filter = true
  config.default_paginator = :paged  # or :offset, :none
  config.resource_cache = Rails.cache
end
```

Test configuration uses `:camelized_key` format (see `test/test_helper.rb:42`).

### Routing

Routes use `jsonapi_resources` helper:

```ruby
jsonapi_resources :articles do
  jsonapi_relationships  # Adds relationship routes
  jsonapi_links :special_tags  # Custom link routes
end
```

Creates:
- Collection: `GET /articles`, `POST /articles`
- Member: `GET /articles/:id`, `PATCH /articles/:id`, `DELETE /articles/:id`
- Relationships: `GET/POST/PATCH/DELETE /articles/:id/relationships/:name`
- Related: `GET /articles/:id/:name`

Route format configurable per namespace (`:underscored_route`, `:dasherized_route`, `:camelized_route`).

## Important Patterns

### Context Pattern

A `context` hash flows through the entire request lifecycle. Use for authorization, scoping, tenant isolation:

```ruby
class ArticlesController < JSONAPI::ResourceController
  def context
    {current_user: current_user, tenant_id: current_tenant.id}
  end
end

class ArticleResource < JSONAPI::Resource
  def records(options = {})
    super.where(tenant_id: context[:tenant_id])
  end
end
```

### Callbacks

Resource callbacks wrap lifecycle events:

```ruby
class ArticleResource < JSONAPI::Resource
  before_save :audit_change
  after_create :send_notification

  # Callbacks: :create, :update, :remove, :save, :replace_fields
  # Also: :replace_to_one_relationship, :replace_to_many_relationship, etc.
end
```

### Custom Processors

Override default operation handling per resource:

```ruby
class ArticleResource < JSONAPI::Resource
  def self.processor_class
    ArticleProcessor
  end
end

class ArticleProcessor < JSONAPI::Processor
  def find
    # Custom find logic
  end
end
```

### Formatters

Pluggable formatters control key/route transformations:

- `JSONAPI::KeyFormatter`: `:dasherized_key`, `:camelized_key`, `:underscored_key`
- `JSONAPI::RouteFormatter`: `:dasherized_route`, `:camelized_route`, `:underscored_route`
- Custom formatters: Inherit from base classes (see `test/test_helper.rb:653-704`)

### Relationship Reflection

Optional feature to automatically update inverse relationships:

```ruby
JSONAPI.configure do |config|
  config.use_relationship_reflection = true
end
```

Maintains referential integrity when creating/updating relationships.

## Testing Patterns

### Test Structure

Tests are organized by:

- `test/controllers/` - Controller tests
- `test/unit/resource/` - Resource tests
- `test/unit/serializer/` - Serializer tests
- `test/unit/processor/` - Processor tests
- `test/integration/` - Integration tests

### Test Helpers

Located in `test/helpers/`:

- `assertions.rb` - Custom assertions
- `functional_helpers.rb` - Controller test helpers
- `value_matchers.rb` - Value matching utilities
- `configuration_helpers.rb` - Config manipulation

### Assertions

Common assertions:

```ruby
# Query count tracking
assert_query_count(3) do
  # code that should execute exactly 3 queries
end

# JSON:API response validation
assert_jsonapi_response 200
assert_jsonapi_get url

# Caching validation
assert_cacheable_jsonapi_get url
assert_cacheable_get :index, params: {filter: {title: 'foo'}}
```

### Testing with Different Rails Versions

The gem supports Rails 5.1+. CI matrix includes multiple Rails versions. Test against specific version:

```bash
export RAILS_VERSION=6.0.3.4; bundle update; bundle exec rake test
```

## Key Files for Common Tasks

### Adding New Resource Features

- `lib/jsonapi/basic_resource.rb` - Core resource logic, callbacks, field definitions
- `lib/jsonapi/active_relation_resource.rb` - ActiveRecord integration, filtering, sorting

### Modifying Request Handling

- `lib/jsonapi/acts_as_resource_controller.rb` - HTTP handling, header verification
- `lib/jsonapi/request.rb` - Parameter parsing, operation creation

### Changing Serialization

- `lib/jsonapi/resource_serializer.rb` - Primary serialization logic
- `lib/jsonapi/response_document.rb` - Response structure (meta, links, errors)
- `lib/jsonapi/cached_response_fragment.rb` - Caching layer

### Query Optimization

- `lib/jsonapi/active_relation/join_manager.rb` - JOIN consolidation
- `lib/jsonapi/resource_set.rb` - Fragment population, cache management

### Routing

- `lib/jsonapi/routing_ext.rb` - Rails routing extensions

## Conventions

- Resources are singular: `ArticleResource`
- Controllers are plural: `ArticlesController`
- Models are singular: `Article`
- Foreign keys: `author_id` (for `has_one :author`)
- Polymorphic relationships supported via `polymorphic: true`
- Resource discovery: `Api::V1::ArticlesController` → `Api::V1::ArticleResource`

## Common Gotchas

- Relationship routes excluded by default in relationship blocks unless `jsonapi_relationships` called
- `config.action_controller.action_on_unpermitted_parameters = :raise` recommended for debugging
- MIME type enforcement is strict: requests must have `Accept: application/vnd.api+json` and `Content-Type: application/vnd.api+json`
- Resource caching requires `cache_field` (default: `updated_at`) to exist on models
- JoinManager aliasing can cause confusion; check generated SQL when debugging complex queries
- Transaction support requires `allow_transactions` config enabled
