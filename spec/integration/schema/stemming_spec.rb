require 'spec_helper'

RSpec.describe 'SettingsTest' do
  it "default" do
    expect_tokenisation :default,
      "It's A Small’s World" => %w(it small world),
      "It's Mitt’s" => %w(it mitt)
  end

  it "uses correct stemming" do
    expect_tokenisation :default,
      "news" => ["news"]
  end

  it "exact match" do
    expect_tokenisation :exact_match,
      "It’s A Small W'rld" => ["it's a small w'rld"]
  end

  it "best bet stemmed match" do
    expect_tokenisation :best_bet_stemmed_match,
      "It’s A Small W'rld" => %w(it a small wrld)
  end

  it "spelling analyzer" do
    expect_tokenisation :spelling_analyzer,
      "It’s Grammed" => ["its", "its grammed", "grammed"]
  end

  it "string for sorting" do
    expect_tokenisation :string_for_sorting,
      "It's A Small W’rld" => ["its a small wrld"]
  end

private

  # Verifies that certain input will be tokenised as expected by the specified
  # analyzer.
  def expect_tokenisation(analyzer, assertions)
    assertions.each do |query, expected_output|
      tokens = fetch_tokens_for_analyzer(query, analyzer)
      expect(expected_output).to eq(tokens)
    end
  end

  def fetch_tokens_for_analyzer(query, analyzer)
    result = client.indices.analyze(index: 'government_test', analyzer: analyzer.to_s, body: query)
    mappings = result['tokens']
    mappings.map { |mapping| mapping['token'] }
  end
end
