require File.expand_path('../../../test_helper', __FILE__)

# Test for Issue #1473: Inverse polymorphic relationship error
# https://github.com/cerebris/jsonapi-resources/issues/1473
#
# This test reproduces the scenario where:
# - Article has_many :article_comments, as: :commentable
# - ArticleComment belongs_to :commentable, polymorphic: true
# - ArticleResource has_many :article_comments, foreign_key_on: :related
# - Requesting articles?include=article_comments should work without
#   attempting to use inverse joins like ArticleComment.joins(:article)

class PolymorphicHasManyTest < ActiveSupport::TestCase
  def setup
    DatabaseCleaner.start
    # Create test data
    @article = Article.create!(title: 'Test Article')
    @comment1 = ArticleComment.create!(
      content: 'First comment',
      commentable: @article
    )
    @comment2 = ArticleComment.create!(
      content: 'Second comment',
      commentable: @article
    )
  end

  def teardown
    DatabaseCleaner.clean
  end

  def test_polymorphic_has_many_find_fragments_with_include
    # This test verifies that we can include polymorphic has_many relationships
    # with foreign_key_on: :related without attempting invalid inverse joins

    resource_klass = ArticleResource
    context = {}

    # Create include directives for article_comments
    include_directives = JSONAPI::IncludeDirective.new(
      resource_klass,
      ['article_comments'],
      allow_remote_includes: false
    )

    # Find fragments should not raise an error about missing inverse relationship
    assert_nothing_raised do
      fragments = resource_klass.find_fragments(
        {},
        {
          context: context,
          include_directives: include_directives
        }
      )

      assert fragments.any?, "Should find article fragments"
    end
  end

  def test_polymorphic_has_many_resource_set_populate
    # Test that populating a resource set with polymorphic includes works correctly

    resource_klass = ArticleResource
    context = {}

    # Find the article fragments
    fragments = resource_klass.find_fragments({}, { context: context })
    assert fragments.any?, "Should find article fragments"

    # Create include directives
    include_directives = JSONAPI::IncludeDirective.new(
      resource_klass,
      ['article_comments'],
      allow_remote_includes: false
    )

    # Create and populate resource set
    resource_set = JSONAPI::ResourceSet.new(resource_klass)
    fragments.each do |fragment|
      resource_set.add_resource_fragment(fragment, include_directives)
    end

    # This should not raise "Can't join 'ArticleComment' to association named 'article'"
    assert_nothing_raised do
      resource_set.populate!(context)
    end

    # Verify that the article_comments are included
    primary_resources = resource_set.resource_set_by_resource_klass_and_id
    assert primary_resources[resource_klass].any?, "Should have article resources"
  end

  def test_polymorphic_has_many_records_includes_work
    # Test that the underlying ActiveRecord includes work correctly

    # This should use Article.includes(:article_comments), not ArticleComment.joins(:article)
    assert_nothing_raised do
      articles = Article.includes(:article_comments).to_a
      assert_equal 1, articles.size
      assert_equal 2, articles.first.article_comments.size
    end
  end
end
