require 'test_helper'

class SearchServerTest < Minitest::Test
  def schema_config
    schema = stub("schema config")
    schema.stubs(:elasticsearch_mappings).returns({})
    schema.stubs(:elasticsearch_settings).returns({})
    schema
  end

  def test_returns_an_index
    search_server = SearchIndices::SearchServer.new("http://l", schema_config, ["mainstream_test", "page-traffic_test"], 'govuk_test', ["mainstream_test"], SearchConfig.new)
    index = search_server.index("mainstream_test")
    assert index.is_a?(SearchIndices::Index)
    assert_equal "mainstream_test", index.index_name
  end

  def test_returns_an_index_for_govuk_index
    search_server = SearchIndices::SearchServer.new("http://l", schema_config, ["mainstream_test", "page-traffic_test"], 'govuk_test', ["mainstream_test"], SearchConfig.new)
    index = search_server.index("govuk_test")
    assert index.is_a?(SearchIndices::Index)
    assert_equal "govuk_test", index.index_name
  end

  def test_raises_an_error_for_unknown_index
    search_server = SearchIndices::SearchServer.new("http://l", schema_config, ["mainstream_test", "page-traffic_test"], 'govuk_test', ["mainstream_test"], SearchConfig.new)
    assert_raises SearchIndices::NoSuchIndex do
      search_server.index("z")
    end
  end

  def test_can_get_multi_index
    search_server = SearchIndices::SearchServer.new("http://l", schema_config, ["mainstream_test", "page-traffic_test"], 'govuk_test', ["mainstream_test"], SearchConfig.new)
    index = search_server.index_for_search(%w{mainstream_test page-traffic_test})
    assert index.is_a?(LegacyClient::IndexForSearch)
    assert_equal ["mainstream_test", "page-traffic_test"], index.index_names
  end

  def test_raises_an_error_for_unknown_index_in_multi_index
    search_server = SearchIndices::SearchServer.new("http://l", schema_config, ["mainstream_test", "page-traffic_test"], 'govuk_test', ["mainstream_test"], SearchConfig.new)
    assert_raises SearchIndices::NoSuchIndex do
      search_server.index_for_search(%w{mainstream_test unknown})
    end
  end
end
