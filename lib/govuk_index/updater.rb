module GovukIndex
  class Updater
    SCROLL_BATCH_SIZE = 500
    PROCESSOR_BATCH_SIZE = 25
    TIMEOUT_SECONDS = 30

    class ImplementationRequired < StandardError; end


    def initialize(source_index:, destination_index:)
      @source_index = source_index
      @destination_index = destination_index
    end

    def run
      scroll_enumerator.each_slice(PROCESSOR_BATCH_SIZE) do |documents|
        worker.perform_async(documents, @destination_index)
      end
    end

    def worker
      raise ImplementationRequired
    end

    def search_body
      raise ImplementationRequired
    end

    private

    def scroll_enumerator
      ScrollEnumerator.new(
        client: Services.elasticsearch(hosts: SearchConfig.instance.base_uri, timeout: TIMEOUT_SECONDS),
        index_names: @source_index,
        search_body: search_body,
        batch_size: SCROLL_BATCH_SIZE
      ) do |record|
        {
          identifier: record.slice(*%w{_id _type _version}),
          document: record.fetch('_source'),
        }
      end
    end
  end
end
