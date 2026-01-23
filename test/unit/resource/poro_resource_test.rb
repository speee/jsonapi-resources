require File.expand_path('../../../test_helper', __FILE__)

# PORO (Plain Old Ruby Object) for testing
class PoroModel
  attr_accessor :id, :name, :created_at

  def initialize(id, name)
    @id = id
    @name = name
    @created_at = Time.now
  end

  # Note: No .all method - this is a PORO, not ActiveRecord

  # Required for jsonapi-resources compatibility
  def valid?(_context = nil)
    true
  end

  def save(_options = {})
    true
  end
end

# Resource for PORO model
class PoroModelResource < JSONAPI::Resource
  model_name 'PoroModel'
  attributes :name

  class << self
    def find_by_key(key, options = {})
      context = options[:context]
      model = PoroModel.new(key, "PORO Item #{key}")
      new(model, context)
    end

    def create(context)
      model = PoroModel.new(SecureRandom.uuid, "New PORO")
      new(model, context)
    end
  end
end

# PORO Resource without find_by_key override (mimics CallbackTelephoneIncomingResource)
class MinimalPoroModelResource < JSONAPI::Resource
  model_name 'PoroModel'
  attributes :name

  class << self
    def create(context)
      model = PoroModel.new(SecureRandom.uuid, "Minimal PORO")
      new(model, context)
    end

    # Note: find_by_key is NOT overridden
    # This should work with the 0.9.x-style create behavior
  end
end

class PoroResourceTest < ActiveSupport::TestCase
  def test_poro_model_does_not_respond_to_all
    # Verify our test PORO doesn't have .all method
    refute PoroModel.respond_to?(:all),
      "PORO model should not respond to :all"
  end

  def test_find_fragments_works_with_poro
    # find_fragments should work with PORO by falling back to find_by_key
    filters = {}
    options = {
      context: {},
      primary_keys: ['key1', 'key2']
    }

    fragments = PoroModelResource.find_fragments(filters, options)

    assert_equal 2, fragments.length, "Should return 2 fragments"

    # Verify fragments have correct structure
    fragments.each do |identity, fragment|
      assert_kind_of JSONAPI::ResourceIdentity, identity
      assert_kind_of JSONAPI::ResourceFragment, fragment
      assert_not_nil fragment.resource, "Fragment should have resource for PORO"
    end
  end

  def test_find_fragments_returns_empty_for_poro_without_keys
    filters = {}
    options = {
      context: {},
      primary_keys: nil
    }

    fragments = PoroModelResource.find_fragments(filters, options)

    assert_equal({}, fragments, "Should return empty hash when no keys")
  end

  def test_find_fragments_with_single_key_for_poro
    filters = {}
    options = {
      context: {},
      primary_keys: 'single_key'
    }

    fragments = PoroModelResource.find_fragments(filters, options)

    assert_equal 1, fragments.length, "Should return 1 fragment"
  end

  def test_active_record_resource_still_uses_original_find_fragments
    # Ensure ActiveRecord resources still use the optimized pluck-based implementation
    # This test verifies we didn't break existing behavior
    filters = { PostResource._primary_key => [1, 2] }
    options = { context: {} }

    # PostResource uses ActiveRecord, should work normally
    fragments = PostResource.find_fragments(filters, options)

    assert_equal 2, fragments.length
    fragments.each do |identity, fragment|
      assert_kind_of JSONAPI::ResourceIdentity, identity
      assert_kind_of JSONAPI::ResourceFragment, fragment
    end
  end

  def test_create_poro_without_find_by_key_override
    # This tests the fix for PORO resources that don't override find_by_key
    # Previously, create would call find_resource_set -> find_fragments -> _model_class.all
    # which would fail for PORO models without .all method
    # With the fix, create should return the created resource directly (0.9.x behavior)

    params = {
      data: {
        type: 'minimal_poro_models',
        attributes: {
          name: 'Test PORO'
        }
      },
      include_directives: JSONAPI::IncludeDirectives.new(MinimalPoroModelResource, []),
      fields: {},
      serializer: JSONAPI::ResourceSerializer.new(MinimalPoroModelResource)
    }

    processor = JSONAPI::Processor.new(MinimalPoroModelResource, :create_resource, params)

    # This should not raise an error (no call to _model_class.all)
    result = processor.create_resource

    assert_kind_of JSONAPI::ResourceSetOperationResult, result
    assert result.code == :created || result.code == 201, "Expected :created or 201, got #{result.code.inspect}"
    assert_not_nil result.resource_set

    # Verify the resource set contains the created resource
    resources = result.resource_set.instance_variable_get(:@resource_klasses)
    assert_equal 1, resources[MinimalPoroModelResource].length
  end
end
