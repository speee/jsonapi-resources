require File.expand_path('../../../test_helper', __FILE__)

# Test for Issue #1467: Demonstrate the problem with ActiveRelationResource and ActiveModel
# https://github.com/cerebris/jsonapi-resources/issues/1467
#
# This test shows that using JSONAPI::Resource (which inherits from ActiveRelationResource)
# with an ActiveModel-based model will fail because ActiveRelationResource expects
# ActiveRecord methods like 'where'

class ActiveModelBrokenTest < ActiveSupport::TestCase
  def setup
    # Seed some test data in the mock store
    SimpleModel.reset_store!
    @model1 = SimpleModel.create(id: 1, name: 'Test 1', description: 'First test')
    @model2 = SimpleModel.create(id: 2, name: 'Test 2', description: 'Second test')
  end

  def teardown
    SimpleModel.reset_store!
  end

  # This test demonstrates the problem: JSONAPI::Resource (ActiveRelationResource)
  # attempts to use ActiveRecord methods on ActiveModel models
  def test_activerelation_resource_fails_with_activemodel
    resource_klass = BrokenActiveModelResource
    context = {}

    # This WILL raise NoMethodError because ActiveRelationResource expects ActiveRecord methods
    # The error could be 'order', 'where', or other ActiveRecord-specific methods
    error = assert_raises(NoMethodError) do
      fragments = resource_klass.find_fragments({}, { context: context })
    end

    # Verify it's trying to use ActiveRecord-like query methods
    assert_match(/undefined method.*(order|where|limit|offset)/, error.message)
  end
end
