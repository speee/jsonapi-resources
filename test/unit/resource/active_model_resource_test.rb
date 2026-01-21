require File.expand_path('../../../test_helper', __FILE__)

# Test for Issue #1467: ActiveModel-based resources fail with 'where' method error
# https://github.com/cerebris/jsonapi-resources/issues/1467
#
# This test reproduces the scenario where:
# - A model uses ActiveModel::Model instead of ActiveRecord::Base
# - The resource should work with BasicResource or proper configuration
# - In v0.10.7+, these resources fail with "undefined method 'where'"

class ActiveModelResourceTest < ActiveSupport::TestCase
  def setup
    # Seed some test data in the mock store
    SimpleModel.reset_store!
    @model1 = SimpleModel.create(id: 1, name: 'Test 1', description: 'First test')
    @model2 = SimpleModel.create(id: 2, name: 'Test 2', description: 'Second test')
  end

  def teardown
    SimpleModel.reset_store!
  end

  # Test that ActiveModel-based resources can be found without using ActiveRecord methods
  def test_find_activemodel_resources
    resource_klass = SimpleModelResource
    context = {}

    # This should not raise "undefined method 'where'"
    assert_nothing_raised do
      fragments = resource_klass.find_fragments({}, { context: context })
      assert fragments.any?, "Should find SimpleModel fragments"
      assert_equal 2, fragments.size, "Should find 2 fragments"
    end
  end

  # Test that ActiveModel-based resources can be filtered
  def test_filter_activemodel_resources
    resource_klass = SimpleModelResource
    context = {}

    # Test with a filter
    filters = { name: 'Test 1' }

    # This should not attempt to call _model_class.where(name: 'Test 1')
    assert_nothing_raised do
      fragments = resource_klass.find_fragments(filters, { context: context })
      assert_equal 1, fragments.size, "Should find 1 filtered fragment"
    end
  end

  # Test that ActiveModel-based resources work with find_by_key
  def test_find_by_key_activemodel_resources
    resource_klass = SimpleModelResource
    context = {}

    # find_by_key should work for ActiveModel resources
    assert_nothing_raised do
      resource = resource_klass.find_by_key(1, context: context)
      assert resource, "Should find resource by key"
      assert_equal 'Test 1', resource.name
    end
  end
end
