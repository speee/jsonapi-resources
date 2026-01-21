require File.expand_path('../../../test_helper', __FILE__)

# Tests for apply_filters public accessibility (0.9.x compatibility)
class ApplyFiltersAccessibilityTest < ActiveSupport::TestCase
  def test_apply_filters_is_publicly_accessible
    # In 0.9.x, apply_filters was public and could be called from outside
    # Verify it's accessible as a public method
    assert PostResource.respond_to?(:apply_filters, false),
      "apply_filters should be a public class method for 0.9.x compatibility"
  end

  def test_apply_filters_can_be_called_externally
    # Verify apply_filters can be called from outside the class
    records = Post.all
    filters = {}

    # This should not raise NoMethodError
    result = PostResource.apply_filters(records, filters)

    assert_kind_of ActiveRecord::Relation, result
  end
end

# Tests for ResourceSetOperationResult backward compatibility
class ResourceSetOperationResultBackwardCompatibilityTest < ActiveSupport::TestCase
  def setup
    # Create a helper to build ResourceSet with resources
  end

  def test_resource_method_returns_first_resource
    # Create a ResourceSet with a single resource using the proper API
    post = Post.find(1)
    resource = PostResource.new(post, nil)

    # Use the ResourceSet with a resource (not nil)
    resource_set = JSONAPI::ResourceSet.new(resource)
    resource_set.mark_populated!

    result = JSONAPI::ResourceSetOperationResult.new(:ok, resource_set)

    # 0.9.x style: result.resource
    assert result.respond_to?(:resource), "ResourceSetOperationResult should respond to :resource for 0.9.x compatibility"
    assert_equal resource, result.resource
  end

  def test_resource_method_returns_nil_for_empty_resource_set
    # Create an empty resource set by passing an empty array
    resource_set = JSONAPI::ResourceSet.new([])
    result = JSONAPI::ResourceSetOperationResult.new(:ok, resource_set)

    assert_nil result.resource
  end

  def test_resources_method_returns_all_resources
    # Create a ResourceSet with multiple resources
    post1 = Post.find(1)
    post2 = Post.find(2)
    resource1 = PostResource.new(post1, nil)
    resource2 = PostResource.new(post2, nil)

    # Use the ResourceSet with an array of resources
    resource_set = JSONAPI::ResourceSet.new([resource1, resource2])
    resource_set.mark_populated!

    result = JSONAPI::ResourceSetOperationResult.new(:ok, resource_set)

    # 0.9.x style: result.resources (for collections)
    assert result.respond_to?(:resources), "ResourceSetOperationResult should respond to :resources for 0.9.x compatibility"
    assert_equal 2, result.resources.length
    assert_includes result.resources, resource1
    assert_includes result.resources, resource2
  end
end
