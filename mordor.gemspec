Gem::Specification.new do |s|
  s.name    = "mordor"
  
  # Do not set the version and date field manually, this is done by the release script
  s.version = "0.0.1"
  s.date    = "2011-09-21"

  s.summary     = "mordor"
  s.description = <<-eos
    Small gem to add MongoDB Resources, resources have attributes that translate into document fields. When an attribute is declared, finders for the attribute are added to the Resource automatically
  eos

  s.add_development_dependency('rake')
  s.add_development_dependency('ruby-debug')
  s.add_development_dependency('rspec', '~> 2.0')

  s.add_development_dependency('extlib')
  s.add_development_dependency('mongo')
  s.add_development_dependency('bson_ext')

  s.add_runtime_dependency('extlib')
  s.add_runtime_dependency('mongo')
  s.add_runtime_dependency('bson_ext')

  s.authors  = ['Jan-Willem Koelewijn', 'Dirkjan Bussink']
  s.email    = ['janwillem.koelewijn@nedap.com', 'dirkjan.bussink@nedap.com']
  s.homepage = 'http://www.nedap.com'

  # The files and test_files directives are set automatically by the release script.
  # Do not change them by hand, but make sure to add the files to the git repository.
  s.files = %w(Rakefile lib/mordor.rb lib/mordor/collection.rb lib/mordor/resource.rb lib/mordor/version.rb mordor.gemspec spec/mordor/connection_spec.rb spec/mordor/resource_spec.rb spec/spec.opts spec/spec_helper.rb tasks/github-gem.rake)
end

