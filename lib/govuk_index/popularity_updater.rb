module GovukIndex
  class PopularityUpdater < Updater
    def self.update(index_name, process_all: false)
      new(
        source_index: index_name,
        destination_index: index_name,
        process_all: process_all,
      ).run
    end

    # This task is designed to migrate data when the schema changes, It waits for the
    # queued jobs to be processed, this is done by monitoring the sidekiq queue and workers.
    # This process should be closely monitored as it is not guaranteed to work.
    def self.migrate(index_name)
      index_group = SearchConfig.instance.search_server.index_group(index_name)
      new_index = index_group.create_index
      index_group.current.with_lock do
        new(
          source_index: index_group.current.real_name,
          destination_index: new_index.real_name,
        ).run
        # need to do this to ensure the new index is fully populated
        SyncUpdater.new(
          source_index: 'mainstream',
          destination_index: new_index.real_name,
        ).run
        # wait for queued tasks to be started
        sleep 1 while(Sidekiq::Queue.new(GovukIndex::PopularityWorker::QUEUE_NAME).size > 0) # rubocop: disable Style/ZeroLengthPredicate
        # wait for started tasks to be finished
        sleep 1 while(Sidekiq::Workers.new.any? { |_, _, work| work['queue'] == GovukIndex::PopularityWorker::QUEUE_NAME })
        index_group.switch_to(new_index)
      end
    end

    def initialize(source_index:, destination_index:, process_all: false)
      @process_all = process_all

      super(
        source_index: source_index,
        destination_index: destination_index,
      )
    end

  private

    def worker
      PopularityWorker
    end

    def search_body
      return { query: { match_all: {} } } if @process_all

      # only sync migrated formats as the rest will be updated via the sync job.
      {
        query: {
          terms: {
            format: MigratedFormats.indexable_formats
          }
        }
      }
    end
  end
end
