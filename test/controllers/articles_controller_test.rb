require File.expand_path('../../test_helper', __FILE__)

# Test for Issue #1473: Inverse polymorphic relationship error
# https://github.com/cerebris/jsonapi-resources/issues/1473

class ArticlesControllerTest < ActionController::TestCase
  def setup
    DatabaseCleaner.start
    JSONAPI.configuration.json_key_format = :underscored_key
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

  # Test that including polymorphic has_many relationships works
  # Issue #1473 reported that this would fail with:
  # "Can't join 'ArticleComment' to association named 'article'"
  def test_index_with_polymorphic_has_many_include
    get :index, params: { include: 'article_comments' }
    assert_response :success
    assert_equal 1, json_response['data'].size
    assert json_response['included'], "Should have included resources"
    assert_equal 2, json_response['included'].size, "Should include 2 comments"
  end

  def test_show_with_polymorphic_has_many_include
    get :show, params: { id: @article.id, include: 'article_comments' }
    assert_response :success
    assert_equal @article.id.to_s, json_response['data']['id']
    assert json_response['included'], "Should have included resources"
    assert_equal 2, json_response['included'].size, "Should include 2 comments"
  end
end
