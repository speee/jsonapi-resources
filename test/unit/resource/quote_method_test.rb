require File.expand_path('../../../test_helper', __FILE__)

class QuoteMethodTest < ActiveSupport::TestCase
  def test_quote_method_does_not_hardcode_double_quotes
    # The quote method should NOT hardcode double quotes
    # It should delegate to the database adapter's quote_column_name
    # This test verifies the implementation uses the adapter, not hardcoded quotes
    field_name = 'test_field'

    # Get the actual implementation's result
    actual = PostResource.send(:quote, field_name)

    # The implementation should use connection.quote_column_name, not hardcode "\"#{field}\""
    # We verify this by checking if the method delegates to the connection
    connection = PostResource._model_class.connection
    expected = connection.quote_column_name(field_name)

    assert_equal expected, actual,
      "quote method should delegate to connection.quote_column_name, not hardcode double quotes"
  end

  def test_quote_uses_mysql_style_backticks_with_mysql_adapter
    # This test verifies the quote method respects the database adapter's quoting style
    # MySQL uses backticks, PostgreSQL/SQLite use double quotes

    field_name = 'test_field'

    # Create a mock connection that uses MySQL-style backticks
    mock_connection = Minitest::Mock.new
    mock_connection.expect(:quote_column_name, "`#{field_name}`", [field_name.to_s])

    # Stub the connection method to return our mock
    PostResource._model_class.stub(:connection, mock_connection) do
      actual = PostResource.send(:quote, field_name)
      assert_equal "`#{field_name}`", actual,
        "quote method should use backticks when MySQL adapter is used"
    end

    mock_connection.verify
  end

  def test_quote_uses_connection_adapter
    # The quote method should delegate to the database adapter's quote_column_name
    # This ensures proper quoting for different databases:
    # - SQLite/PostgreSQL: double quotes (")
    # - MySQL: backticks (`)
    field_name = 'test_field'
    expected = PostResource._model_class.connection.quote_column_name(field_name)
    actual = PostResource.send(:quote, field_name)

    assert_equal expected, actual,
      "quote method should use connection adapter's quote_column_name"
  end

  def test_quote_with_symbol_field
    field_name = :test_field
    expected = PostResource._model_class.connection.quote_column_name(field_name.to_s)
    actual = PostResource.send(:quote, field_name)

    assert_equal expected, actual,
      "quote method should handle symbol field names"
  end

  def test_concat_table_field_quoted
    table = 'posts'
    field = 'title'
    connection = PostResource._model_class.connection
    expected = "#{connection.quote_column_name(table)}.#{connection.quote_column_name(field)}"
    actual = PostResource.send(:concat_table_field, table, field, true)

    assert_equal expected, actual,
      "concat_table_field with quoted=true should use proper database quoting"
  end

  def test_alias_table_field_quoted
    table = 'posts'
    field = 'title'
    connection = PostResource._model_class.connection
    expected = connection.quote_column_name("#{table}_#{field}")
    actual = PostResource.send(:alias_table_field, table, field, true)

    assert_equal expected, actual,
      "alias_table_field with quoted=true should use proper database quoting"
  end

  def test_sql_field_with_alias_uses_proper_quoting
    table = 'posts'
    field = 'title'
    connection = PostResource._model_class.connection
    quoted_table_field = "#{connection.quote_column_name(table)}.#{connection.quote_column_name(field)}"
    quoted_alias = connection.quote_column_name("#{table}_#{field}")
    expected_sql = "#{quoted_table_field} AS #{quoted_alias}"

    actual = PostResource.send(:sql_field_with_alias, table, field, true)

    assert actual.is_a?(Arel::Nodes::SqlLiteral),
      "sql_field_with_alias should return an Arel::Nodes::SqlLiteral"
    assert_equal expected_sql, actual.to_s,
      "sql_field_with_alias should use proper database quoting"
  end
end
