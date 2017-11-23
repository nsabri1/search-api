class SynonymParser
  class InvalidSynonymConfig < StandardError; end

  VALID_KEYS = %w(both search index).freeze

  def parse(config)
    index_synonyms = Synonyms.new(:index)
    search_synonyms = Synonyms.new(:search)

    config.each do |synonyms|
      validate_synonym_count!(synonyms)

      key, synonym = synonyms.first
      validate_key!(key)

      if %w(search both).include?(key)
        search_synonyms << synonym
      end
      if %w(index both).include?(key)
        index_synonyms << synonym
      end
    end

    [index_synonyms, search_synonyms]
  end

private

  def validate_key!(key)
    unless VALID_KEYS.include?(key)
      raise InvalidSynonymConfig.new(
        "Unknown synonym key '#{key}'. Expected one of: #{VALID_KEYS.join(', ')}"
      )
    end
  end

  def validate_synonym_count!(synonyms)
    if synonyms.count > 1
      raise InvalidSynonymConfig.new(
        <<~MESSAGE
          More than one term defined together: #{synonyms}. Each synonym should be defined as a separate item, e.g.
          - search: 'foo => bar'
          - index: 'baz, qux'
        MESSAGE
      )
    end
  end

  def validate_term!(term, existing_terms, key)
    if existing_terms.include?(term)
      raise InvalidSynonymConfig.new("Synonym '#{term}' already defined for '#{key}'")
    end
  end

  class Synonyms
    def initialize(synonym_type)
      @synonym_type = synonym_type
      @synonyms = []
      @unique_terms = []
    end

    def <<(synonym)
      synonym_terms = synonym
        .split("=>")
        .first
        .split(",")
        .map(&:strip)

      synonym_terms.each do |term|
        validate_term!(term)
        unique_terms << term
      end

      synonyms << synonym
    end

    def es_config
      # Returns the configuration to pass to elasticsearch to define a filter
      # which applies these synonyms.  Should be passed in the schema under the
      # path `settings.analysis.filter.<filter_name>`.
      {
        type: :synonym,
        synonyms: synonyms
      }
    end

  private

    attr_reader :synonyms, :synonym_type, :unique_terms

    def validate_term!(term)
      if unique_terms.include?(term)
        raise InvalidSynonymConfig.new("Synonym '#{term}' already defined for '#{synonym_type}'")
      end
    end
  end
end
