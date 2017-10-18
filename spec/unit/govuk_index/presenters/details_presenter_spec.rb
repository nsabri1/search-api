require 'spec_helper'

RSpec.describe GovukIndex::DetailsPresenter do
  it "details_with_govspeak_and_text_html" do
    details = {
      "body" => [
        { "content_type" => "text/govspeak", "content" => "**hello**" },
        { "content_type" => "text/html", "content" => "<strong>hello</strong>" }
      ]
    }

    expect(details_presenter(details).indexable_content).to eq("hello")
  end

  it "details_with_parts" do
    details = {
      "parts" => [
        {
          "title" => "title 1",
          "slug" => "title-1",
          "body" => [
            { "content_type" => "text/govspeak", "content" => "**hello**" },
            { "content_type" => "text/html", "content" => "<strong>hello</strong>" }
          ],
        },
        {
          "title" => "title 2",
          "slug" => "title-2",
          "body" => [
            { "content_type" => "text/govspeak", "content" => "**goodbye**" },
            { "content_type" => "text/html", "content" => "<strong>goodbye</strong>" }
          ],
        }
      ]
    }

    expect(details_presenter(details).indexable_content).to eq("title 1\n\nhello\n\ntitle 2\n\ngoodbye")
  end

  it "mapped_licence_fields" do
    details = {
      "continuation_link" => "http://www.on-and-on.com",
      "external_related_links" => [],
      "licence_identifier" => "1234-5-6",
      "licence_short_description" => "short description",
      "licence_overview" => [
        { "content_type" => "text/govspeak", "content" => "**overview**" },
        { "content_type" => "text/html", "content" => "<strong>overview</strong>" }
      ],
      "will_continue_on" => "on and on",
    }

    presenter = details_presenter(details, "licence")

    expect(presenter.licence_identifier).to eq(details["licence_identifier"])
    expect(presenter.licence_short_description).to eq(details["licence_short_description"])
  end

  it "when_additional_indexable_content_keys_are_specified" do
    details = {
      "external_related_links" => [],
      "introductory_paragraph" => [
        { "content_type" => "text/govspeak", "content" => "**introductory paragraph**" },
        { "content_type" => "text/html", "content" => "<strong>introductory paragraph</strong>" }
      ],
      "more_information" => "more information",
      "start_button_text" => "Start now",
    }

    expect(details_presenter(details, %w(introductory_paragraph more_information)).indexable_content).to eq("introductory paragraph\n\nmore information")
  end

  def details_presenter(details, indexable_content_keys = %w(body parts))
    described_class.new(
      details: details,
      indexable_content_keys: indexable_content_keys,
      sanitiser: GovukIndex::IndexableContentSanitiser.new
    )
  end
end