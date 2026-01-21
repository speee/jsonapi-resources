require File.expand_path('../../../test_helper', __FILE__)

# Tests for backward compatibility with 0.9.x API
class BackwardCompatibilityTest < ActiveSupport::TestCase
  # Test find_by_key with old signature: find_by_key(id, context)
  # New signature: find_by_key(key, options = {})
  def test_find_by_key_with_old_signature
    # 0.9.x style: find_by_key(id, context)
    # In 0.9.x, context was passed directly as second argument
    # In 0.10+, context should be passed as options[:context]
    # For backward compatibility, if second arg is a Hash without :context key,
    # it should still work (context will be nil in resource)
    context = { current_user: 'test_user' }
    resource = PostResource.find_by_key(1, context)

    assert_not_nil resource
    assert_equal 1, resource.id
  end

  def test_find_by_key_with_new_signature
    # 0.10+ style: find_by_key(key, options = {})
    context = { current_user: 'test_user' }
    resource = PostResource.find_by_key(1, context: context)

    assert_not_nil resource
    assert_equal 1, resource.id
  end

  def test_find_by_key_without_context
    # find_by_key without any context
    resource = PostResource.find_by_key(1)

    assert_not_nil resource
    assert_equal 1, resource.id
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
