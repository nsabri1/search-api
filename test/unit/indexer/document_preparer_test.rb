require "test_helper"
require "indexer"

describe Indexer::DocumentPreparer do
  describe "#prepared" do
    it "populates popularities" do
      stub_tagging_lookup

      doc_hash = {
        "link" => "/some-link",
      }

      updated_doc_hash = Indexer::DocumentPreparer.new("fake_client", "fake_index").prepared(
        doc_hash,
        { "/some-link" => 0.5 }, true
      )

      assert_equal 0.5, updated_doc_hash["popularity"]
    end

    it "adds missing fields for hmrc manual" do
      stub_tagging_lookup

      doc_hash = {
        "link" => "/some-link",
        "format" => "hmrc_manual",
      }

      updated_doc_hash = Indexer::DocumentPreparer.new("fake_client", "fake_index").prepared(
        doc_hash,
        {},
        true
      )

      assert_equal "hmrc_manual", updated_doc_hash["content_store_document_type"]
      assert updated_doc_hash["publishing_app"]
      assert updated_doc_hash["rendering_app"]
    end

    it "adds missing fields for hmrc manual section" do
      stub_tagging_lookup

      doc_hash = {
        "link" => "/some-link",
        "format" => "hmrc_manual_section",
      }

      updated_doc_hash = Indexer::DocumentPreparer.new("fake_client", "fake_index").prepared(
        doc_hash,
        {},
        true
      )

      assert_equal "hmrc_manual_section", updated_doc_hash["content_store_document_type"]
      assert updated_doc_hash["publishing_app"]
      assert updated_doc_hash["rendering_app"]
    end

    it "adds document type groupings" do
      stub_tagging_lookup

      doc_hash = {
        "link" => "/some-link",
        "content_store_document_type" => "detailed_guide",
      }

      updated_doc_hash = Indexer::DocumentPreparer.new("fake_client", "fake_index").prepared(
        doc_hash,
        {},
        true
      )

      assert_equal "guidance", updated_doc_hash["navigation_document_supertype"]
    end
  end
end
