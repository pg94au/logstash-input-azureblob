# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/inputs/azureblob"

describe LogStash::Inputs::Example do

  before :all do
    @account_name = ENV["account_name"]# || fail "account_name, access_key and container environment variables must be set",
    expect(@account_name).not_to eq(nil), "account_name, access_key and container environment variables must be set"
    @access_key = ENV["access_key"]# || fail "account_name, access_key and container environment variables must be set",
    expect(@access_key).not_to eq(nil), "account_name, access_key and container environment variables must be set"
    @container = ENV["container"]# || fail "account_name, access_key and container environment variables must be set",
    expect(@container).not_to eq(nil), "account_name, access_key and container environment variables must be set"
  end

  it_behaves_like "an interruptible input plugin" do
    let(:config) { {
      "interval" => 100,
      "account_name" => @account_name, # ENV["account_name"],
      "access_key" => @access_key, # ENV["access_key"],
      "container" => @container # ENV["container"]
    } }
  end

end
