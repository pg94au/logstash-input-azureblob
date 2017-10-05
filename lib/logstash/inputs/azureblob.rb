# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "azure/storage"

# Generate a repeating message.
#
# This plugin is intented only as an example.

class LogStash::Inputs::Example < LogStash::Inputs::Base
  config_name "azureblob"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain"

  # The message string to use in the event.
  config :message, :validate => :string, :default => "Hello World!"

  # Set how frequently messages should be sent.
  #
  # The default, `1`, means send a message every second.
  config :interval, :validate => :number, :default => 1

  # The Azure storage account name.
  config :account_name, :validate => :string, :required => true

  # The Azure storage access key.
  config :access_key, :validate => :string, :required => true

  # The blob container name.
  config :container, :validate => :string, :requried => true

  public
  def register
  end # def register

  def run(queue)
    # we can abort the loop if stop? becomes true
    while !stop?
      send_logs_to_queue(queue)

      # because the sleep interval can be big, when shutdown happens
      # we want to be able to abort the sleep
      # Stud.stoppable_sleep will frequently evaluate the given block
      # and abort the sleep(@interval) if the return value is true
      Stud.stoppable_sleep(@interval) { stop? }
    end # loop
  end # def run

  def send_logs_to_queue(queue)
    azure_client = Azure::Storage::Client.create(:storage_account_name => @account_name, :storage_access_key => @access_key)
    blob_client = azure_client.blob_client

    blobs = list_all_blobs(blob_client, @container)

    # Sort by last modified date so newest come last.  Format is: Wed, 30 Aug 2017 22:19:03 GMT
    blobs = blobs.sort_by {|blob| DateTime.parse(blob.properties[:last_modified])}

    blobs.each do |blob|
      blob, content = blob_client.get_blob(@container, blob.name)

      event = LogStash::Event.new("message" => content, "container" => @container)
      decorate(event)
      queue << event
    end
  end

  def stop
    # nothing to do in this case so it is not necessary to define stop
    # examples of common "stop" tasks:
    #  * close sockets (unblocking blocking reads/accepts)
    #  * cleanup temporary files
    #  * terminate spawned threads
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
end # class LogStash::Inputs::Example
