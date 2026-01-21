require File.expand_path('../../../test_helper', __FILE__)

# Test for Issue #1465: ActiveSupport::Deprecation private method error in Rails 7.2
# https://github.com/cerebris/jsonapi-resources/issues/1465
#
# Rails 7.2 made ActiveSupport::Deprecation.warn a private method
# This test ensures our warn_deprecated helper handles both old and new Rails versions

class DeprecationTest < ActiveSupport::TestCase
  def test_warn_deprecated_does_not_raise_error
    # This should not raise NoMethodError: private method `warn' called
    assert_nothing_raised do
      JSONAPI.warn_deprecated('Test deprecation warning')
    end
  end

  def test_warn_deprecated_with_activerecord_present
    # Ensure the warning works when ActiveSupport::Deprecation is available
    skip 'ActiveSupport::Deprecation not available' unless defined?(ActiveSupport::Deprecation)

    assert_nothing_raised do
      JSONAPI.warn_deprecated('Test deprecation with ActiveSupport')
    end
  end

  def test_warn_deprecated_with_multiple_calls
    # Test that multiple calls don't cause issues
    # This is especially important for Rails 7.2 compatibility
    assert_nothing_raised do
      3.times do |i|
        JSONAPI.warn_deprecated("Test deprecation warning #{i}")
      end
    end
  end
end
