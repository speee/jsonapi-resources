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
end
