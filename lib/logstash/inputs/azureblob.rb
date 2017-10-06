# encoding: utf-8
require "azure/storage"
require "concurrent"
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"

# This plugin is able to retrieve logged events from Azure blob storage.

class LogStash::Inputs::AzureBlob < LogStash::Inputs::Base
  config_name "azureblob"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain"

  # The message string to use in the event.
  config :message, :validate => :string, :default => "Hello World!"

  # Set how frequently messages should be sent.
  #
  # The default, `1`, means send a message every second.
  config :interval, :validate => :number, :default => 1

  # The number of threads utilized to retrieve blobs.
  config :threads, :validate => :number, :default => 20

  # The Azure storage account name.
  config :account_name, :validate => :string, :required => true

  # The Azure storage access key.
  config :access_key, :validate => :string, :required => true

  # The blob container name.
  config :container, :validate => :string, :requried => true


  public
  def register
    @logger.info("Creating thread pool with #{@threads} threads.")
    @pool = Concurrent::ThreadPoolExecutor.new(
      min_threads: @threads,
      max_threads: @threads,
      max_queue: 0
    )
  end

  def run(queue)
    # we can abort the loop if stop? becomes true
    while !stop?
      send_logs_to_queue(queue)

      # because the sleep interval can be big, when shutdown happens
      # we want to be able to abort the sleep
      # Stud.stoppable_sleep will frequently evaluate the given block
      # and abort the sleep(@interval) if the return value is true
      @logger.info("Sleeping for #{@interval} seconds.")
      Stud.stoppable_sleep(@interval) { stop? }
    end # loop
  end

  def send_logs_to_queue(queue)
    azure_client = Azure::Storage::Client.create(:storage_account_name => @account_name, :storage_access_key => @access_key)
    blob_client = azure_client.blob_client

    blobs = list_all_blobs(blob_client, @container)

    # Sort by last modified date so newest come last.  Format is: Wed, 30 Aug 2017 22:19:03 GMT
    blobs = blobs.sort_by {|blob| DateTime.parse(blob.properties[:last_modified])}

    @logger.info("Found #{blobs.length} blobs to be retrieved.")

    blobs.each do |blob|
      @pool.post do
        if !stop?
          @logger.debug("Fetching blob #{blob.name}")
          blob, content = blob_client.get_blob(@container, blob.name)

          @logger.debug("Queueing event for blob #{blob.name}")
          event = LogStash::Event.new("message" => content, "container" => @container)
          decorate(event)
          queue << event

          @logger.debug("Deleting blob #{blob.name}")
          blob_client.delete_blob(@container, blob.name)
          @logger.debug("Finished processing blob #{blob.name}")
        end
      end

      if stop?
        @logger.info("Received request to shutdown while iterating through blobs to be retrieved.")
        break
      end
    end
  end

  def stop
    @logger.info("Shutting down thread pool.")
    @pool.shutdown
    @logger.info("Waiting for thread pool to terminate.")
    @pool.wait_for_termination
    @logger.info("Done.")
  end

  def list_all_blobs(blob_client, container)
    blobs = Set.new []
    continuation_token = NIL
    loop do
      # Need to limit the returned number of the returned entries to avoid out of memory exception.
      entries = blob_client.list_blobs(container, { :timeout => 60, :marker => continuation_token, :max_results => 100 })
      entries.each do |entry|
        blobs << entry
      end
      continuation_token = entries.continuation_token
      break if continuation_token.empty?
    end
    return blobs.to_a
  end
end
