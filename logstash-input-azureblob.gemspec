Gem::Specification.new do |s|
  s.name = 'logstash-input-azureblob'
  s.version         = '0.1.0'
  s.licenses = ['Apache License (2.0)']
  s.summary = "This input plugin retrieves logs from Azure blob storage as written by the Log4Net appender."
  s.description     = "This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname. This gem is not a stand-alone program"
  s.authors = ["Paul Grebenc"]
  s.email = 'paul@grebenc.ca'
  s.homepage = "http://paul.grebenc.ca"
  s.require_paths = ["lib"]

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core-plugin-api', '>= 1.60', '<= 2.99'
  s.add_runtime_dependency 'logstash-codec-plain', '~> 3.0'
  s.add_runtime_dependency 'stud', '~> 0.0', '>= 0.0.22'
  s.add_runtime_dependency 'azure-storage', '~> 0.14.0.preview'
  s.add_development_dependency 'logstash-devutils', '~> 1.3'
end
