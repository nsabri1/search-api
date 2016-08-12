require "uri"

module LegacyClient
  class ScrollEnumerator < Enumerator
    # How long to hold a scroll cursor open between requests
    # We want to keep this low (eg, 1 minute), because scroll contexts can be
    # quite expensive.
    # However, the scroll timeout in old releases of elasticsearch is based on
    # the time since the scan operation started, not the time since the last
    # activity happened in the scan, so until we upgrade to elasticsearch
    # 0.90.12+, we should set this high.
    SCROLL_TIMEOUT_MINUTES = 60

    # The number of documents to retrieve at once.
    # Gotcha: this is actually the number of documents per shard, so there will
    # be some multiple of this number per page.
    DEFAULT_BATCH_SIZE = 50

    attr_reader :size

    def initialize(client:, index_names:, search_body:, batch_size: DEFAULT_BATCH_SIZE, &block)
      raise ArgumentError, "Result processing block is required" unless block

      @client = client
      @index_names = index_names
      scroll_result = initial_scroll_result(batch_size, search_body)
      @size = scroll_result["hits"]["total"]

      # Pull out the results as they are needed
      super() do |yielder|
        # Get the initial scroll ID from the response to the initial request
        scroll_id = scroll_result["_scroll_id"]

        loop do
          # Get the next page and extract the next scroll ID from it
          page = next_page(scroll_id)
          scroll_id = page.fetch("_scroll_id") # Error if scroll ID absent

          # The way we tell we've got through all the results is when
          # elasticsearch gives us an empty array of hits. This means all the
          # shards have run out of results.
          if page["hits"]["hits"].any?
            logger.debug do
              hits_on_page = page["hits"]["hits"].size
              "Retrieved #{hits_on_page} of #{size} documents"
            end
            page["hits"]["hits"].each do |hit|
              yielder << yield(hit)
            end
          else
            break
          end
        end
      end
    end

  private

    attr_reader :client

    def next_page(scroll_id)
      client.scroll(scroll_id: scroll_id, scroll: "#{SCROLL_TIMEOUT_MINUTES}m")
    end

    def initial_scroll_result(batch_size, search_body)
      # Set off a scan query to get back a scroll ID and result count
      client.search(
        index: @index_names,
        search_type: "scan",
        scroll: "#{SCROLL_TIMEOUT_MINUTES}m",
        size: batch_size,
        body: search_body
      )
    end

    def logger
      Logging.logger[self]
    end
  end
end
