require File.expand_path('../../../test_helper', __FILE__)

class RoutesTest < ActionDispatch::IntegrationTest

  # def test_dump_routes
  #   r = {}
  #
  #   Rails.application.routes.routes.each do |route|
  #     r[route.path.spec.right.left.to_s] ||= {routes: {}}
  #     r[route.path.spec.right.left.to_s][:routes][route.path.spec.to_s] ||= {}
  #     r[route.path.spec.right.left.to_s][:routes][route.path.spec.to_s][route.defaults[:action]] = route
  #   end
  #
  #   r
  # end

  def test_routing_post
    assert_routing({path: 'posts', method: :post},
                   {controller: 'posts', action: 'create'})
  end

  def test_routing_patch
    assert_routing({path: '/posts/1', method: :patch},
                   {controller: 'posts', action: 'update', id: '1'})
  end

  def test_routing_posts_show
    assert_routing({path: '/posts/1', method: :get},
                   {action: 'show', controller: 'posts', id: '1'})
  end

  def test_routing_posts_links_author_show
    assert_routing({path: '/posts/1/relationships/author', method: :get},
                   {controller: 'posts', action: 'show_relationship', post_id: '1', relationship: 'author'})
  end

  def test_routing_posts_links_author_destroy
    assert_routing({path: '/posts/1/relationships/author', method: :delete},
                   {controller: 'posts', action: 'destroy_relationship', post_id: '1', relationship: 'author'})
  end

  def test_routing_posts_links_author_update
    assert_routing({path: '/posts/1/relationships/author', method: :patch},
                   {controller: 'posts', action: 'update_relationship', post_id: '1', relationship: 'author'})
  end

  def test_routing_posts_links_tags_show
    assert_routing({path: '/posts/1/relationships/tags', method: :get},
                   {controller: 'posts', action: 'show_relationship', post_id: '1', relationship: 'tags'})
  end

  def test_routing_posts_links_tags_destroy
    assert_routing({path: '/posts/1/relationships/tags', method: :delete},
                   {controller: 'posts', action: 'destroy_relationship', post_id: '1', relationship: 'tags'})
  end

  def test_routing_posts_links_tags_create
    assert_routing({path: '/posts/1/relationships/tags', method: :post},
                   {controller: 'posts', action: 'create_relationship', post_id: '1', relationship: 'tags'})
  end

  def test_routing_posts_links_tags_update_acts_as_set
    assert_routing({path: '/posts/1/relationships/tags', method: :patch},
                   {controller: 'posts', action: 'update_relationship', post_id: '1', relationship: 'tags'})
  end

  def test_routing_uuid
    assert_routing({path: '/pets/v1/cats/f1a4d5f2-e77a-4d0a-acbb-ee0b98b3f6b5', method: :get},
                   {action: 'show', controller: 'pets/v1/cats', id: 'f1a4d5f2-e77a-4d0a-acbb-ee0b98b3f6b5'})
  end

  # ToDo: refute this routing
  # def test_routing_uuid_bad_format
  #   assert_routing({path: '/pets/v1/cats/f1a4d5f2-e77a-4d0a-acbb-ee0b9', method: :get},
  #                  {action: 'show', controller: 'pets/v1/cats', id: 'f1a4d5f2-e77a-4d0a-acbb-ee0b98'})
  # end

  # Polymorphic
  # ToDo: refute this routing. Polymorphic relationships can't support a shared set of filters or includes so
  # this this route is no longer supported
  # def test_routing_polymorphic_show_related_resource
  #   assert_routing(
  #     {
  #       path: '/pictures/1/imageable',
  #       method: :get
  #     },
  #     {
  #       relationship: 'imageable',
  #       source: 'pictures',
  #       controller: 'imageables',
  #       action: 'show_related_resource',
  #       picture_id: '1'
  #     }
  #   )
  # end

  def test_routing_polymorphic_patch_related_resource
    assert_routing(
      {
        path: '/pictures/1/relationships/imageable',
        method: :patch
      },
      {
        relationship: 'imageable',
        controller: 'pictures',
        action: 'update_relationship',
        picture_id: '1'
      }
    )
  end

  def test_routing_polymorphic_delete_related_resource
    assert_routing(
      {
        path: '/pictures/1/relationships/imageable',
        method: :delete
      },
      {
        relationship: 'imageable',
        controller: 'pictures',
        action: 'destroy_relationship',
        picture_id: '1'
      }
    )
  end

  # V1
  def test_routing_v1_posts_show
    assert_routing({path: '/api/v1/posts/1', method: :get},
                   {action: 'show', controller: 'api/v1/posts', id: '1'})
  end

  def test_routing_v1_posts_delete
    assert_routing({path: '/api/v1/posts/1', method: :delete},
                   {action: 'destroy', controller: 'api/v1/posts', id: '1'})
  end

  def test_routing_v1_posts_links_writer_show
    assert_routing({path: '/api/v1/posts/1/relationships/writer', method: :get},
                   {controller: 'api/v1/posts', action: 'show_relationship', post_id: '1', relationship: 'writer'})
  end

  # V2
  def test_routing_v2_posts_links_author_show
    assert_routing({path: '/api/v2/posts/1/relationships/author', method: :get},
                   {controller: 'api/v2/posts', action: 'show_relationship', post_id: '1', relationship: 'author'})
  end

  def test_routing_v2_preferences_show
    assert_routing({path: '/api/v2/preferences', method: :get},
                   {action: 'show', controller: 'api/v2/preferences'})
  end

  # V3
  def test_routing_v3_posts_show
    assert_routing({path: '/api/v3/posts/1', method: :get},
                   {action: 'show', controller: 'api/v3/posts', id: '1'})
  end

  # V4 camelCase
  def test_routing_v4_posts_show
    assert_routing({path: '/api/v4/posts/1', method: :get},
                   {action: 'show', controller: 'api/v4/posts', id: '1'})
  end

  def test_routing_v4_isoCurrencies_resources
    assert_routing({path: '/api/v4/isoCurrencies/USD', method: :get},
                   {action: 'show', controller: 'api/v4/iso_currencies', id: 'USD'})
  end

  def test_routing_v4_expenseEntries_resources
    assert_routing({path: '/api/v4/expenseEntries/1', method: :get},
                   {action: 'show', controller: 'api/v4/expense_entries', id: '1'})

    assert_routing({path: '/api/v4/expenseEntries/1/relationships/isoCurrency', method: :get},
                   {controller: 'api/v4/expense_entries', action: 'show_relationship', expense_entry_id: '1', relationship: 'iso_currency'})
  end

  # V5 dasherized
  def test_routing_v5_posts_show
    assert_routing({path: '/api/v5/posts/1', method: :get},
                   {action: 'show', controller: 'api/v5/posts', id: '1'})
  end

  def test_routing_v5_isoCurrencies_resources
    assert_routing({path: '/api/v5/iso-currencies/USD', method: :get},
                   {action: 'show', controller: 'api/v5/iso_currencies', id: 'USD'})
  end

  def test_routing_v5_expenseEntries_resources
    assert_routing({path: '/api/v5/expense-entries/1', method: :get},
                   {action: 'show', controller: 'api/v5/expense_entries', id: '1'})

    assert_routing({path: '/api/v5/expense-entries/1/relationships/iso-currency', method: :get},
                   {controller: 'api/v5/expense_entries', action: 'show_relationship', expense_entry_id: '1', relationship: 'iso_currency'})
  end

  def test_routing_authors_show
    assert_routing({path: '/api/v5/authors/1', method: :get},
                   {action: 'show', controller: 'api/v5/authors', id: '1'})
  end

  def test_routing_author_links_posts_create_not_acts_as_set
    assert_routing({path: '/api/v5/authors/1/relationships/posts', method: :post},
                   {controller: 'api/v5/authors', action: 'create_relationship', author_id: '1', relationship: 'posts'})
  end

  def test_routing_list_items_index
    assert_routing({path: '/list_items', method: :get},
                   {controller: 'list_items', action: 'index'})
  end

  def test_routing_list_related_items
    assert_routing({path: '/lists/1/items', method: :get},
                   {controller: 'list_items', action: 'index_related_resources', relationship: 'items', list_id: '1', source: 'lists'})
  end

  def test_list_items_route_helper_name
    assert_equal(list_items_path, '/list_items')
  end

  #primary_key
  def test_routing_primary_key_jsonapi_resources
    assert_routing({path: '/iso_currencies/USD', method: :get},
                   {action: 'show', controller: 'iso_currencies', id: 'USD'})
  end

  # ToDo: Refute routing
  # def test_routing_v3_posts_delete
  #   assert_routing({ path: '/api/v3/posts/1', method: :delete },
  #                  {action: 'destroy', controller: 'api/v3/posts', id: '1'})
  # end

  # def test_routing_posts_links_author_except_destroy
  #   assert_routing({ path: '/api/v3/posts/1/relationships/author', method: :delete },
  #                  { controller: 'api/v3/posts', action: 'destroy_relationship', post_id: '1', relationship: 'author' })
  # end
  #
  # def test_routing_posts_links_tags_only_create_show
  #   assert_routing({ path: '/api/v3/posts/1/relationships/tags/1,2', method: :delete },
  #                  { controller: 'api/v3/posts', action: 'destroy_relationship', post_id: '1', keys: '1,2', relationship: 'tags' })
  # end

  # Test that non-acts-as-set to_many relationship update route is not created

  # Rails 8.1 compatibility tests (Issue #1479)
  # These tests verify that jsonapi_resources generates relationship routes correctly
  # in Rails 8.1+, where ActionDispatch::Routing::Mapper::Resources::Resource#initialize
  # changed to require keyword arguments.

  def test_routing_articles_show
    assert_routing({path: '/articles/1', method: :get},
                   {action: 'show', controller: 'articles', id: '1'})
  end

  def test_routing_articles_relationship_comments_show
    # Tests that has_many relationship routes are automatically generated
    # when using jsonapi_resources without an explicit block
    assert_routing({path: '/articles/1/relationships/article_comments', method: :get},
                   {controller: 'articles', action: 'show_relationship', article_id: '1', relationship: 'article_comments'})
  end

  def test_routing_articles_relationship_comments_create
    # Tests to_many relationship creation route
    assert_routing({path: '/articles/1/relationships/article_comments', method: :post},
                   {controller: 'articles', action: 'create_relationship', article_id: '1', relationship: 'article_comments'})
  end

  def test_routing_articles_relationship_comments_update
    # Tests to_many relationship update route
    assert_routing({path: '/articles/1/relationships/article_comments', method: :patch},
                   {controller: 'articles', action: 'update_relationship', article_id: '1', relationship: 'article_comments'})
  end

  def test_routing_articles_relationship_comments_destroy
    # Tests to_many relationship deletion route
    assert_routing({path: '/articles/1/relationships/article_comments', method: :delete},
                   {controller: 'articles', action: 'destroy_relationship', article_id: '1', relationship: 'article_comments'})
  end

  def test_routing_article_comments_relationship_commentable_show
    # Tests polymorphic belongs_to relationship route
    assert_routing({path: '/article_comments/1/relationships/commentable', method: :get},
                   {controller: 'article_comments', action: 'show_relationship', article_comment_id: '1', relationship: 'commentable'})
  end

end
