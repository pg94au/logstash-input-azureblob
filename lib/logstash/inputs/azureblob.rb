# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "azure"

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
    #@host = Socket.gethostname
    Azure.config.storage_account_name = @account_name
    Azure.cnofig.storage_access_key = @access_key
  end # def register

  def run(queue)
    # we can abort the loop if stop? becomes true
    while !stop?
      #event = LogStash::Event.new("message" => @message, "host" => @host)
      #decorate(event)
      #queue << event

      # because the sleep interval can be big, when shutdown happens
      # we want to be able to abort the sleep
      # Stud.stoppable_sleep will frequently evaluate the given block
      # and abort the sleep(@interval) if the return value is true
      Stud.stoppable_sleep(@interval) { stop? }
    end # loop
  end # def run

  def send_logs_to_queue(queue)
    azure_blob_service = Azure::Blob::BlobService.new

    blobs = azure_blob_service.list_blobs(@container)

    # Sort by last modified date so newest come last.  Format is: Wed, 30 Aug 2017 22:19:03 GMT
    blobs = blobs.sort_by {|blob| DateTime.parse(blob.properties[:last_modified])}

    blobs.each do |blob|
      blob, content = azure_blob_service.get_blob(@container, blob.name)

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
end # class LogStash::Inputs::Example
