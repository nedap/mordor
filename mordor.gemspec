Gem::Specification.new do |s|
  s.name    = "mordor"
  
  # Do not set the version and date field manually, this is done by the release script
  s.version = "0.2.17"
  s.date    = "2013-01-22"

  s.summary     = "mordor"
  s.description = <<-eos
    Small gem to add MongoDB Resources, resources have attributes that translate into document fields. When an attribute is declared, finders for the attribute are added to the Resource automatically
  eos

  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', '~> 2.0')
  s.add_development_dependency('json')

  s.add_development_dependency('extlib')
  s.add_development_dependency('mongo')

  s.add_runtime_dependency('extlib')
  s.add_runtime_dependency('mongo')
  s.add_runtime_dependency('json')

  s.authors  = ['Jan-Willem Koelewijn', 'Dirkjan Bussink']
  s.email    = ['janwillem.koelewijn@nedap.com', 'dirkjan.bussink@nedap.com']
  s.homepage = 'http://www.nedap.com'

  # The files and test_files directives are set automatically by the release script.
  # Do not change them by hand, but make sure to add the files to the git repository.
  s.files = %w(.gitignore .travis.yml Gemfile Gemfile.lock LICENSE README.md Rakefile lib/mordor.rb lib/mordor/collection.rb lib/mordor/config.rb lib/mordor/resource.rb lib/mordor/version.rb mordor.gemspec spec/mordor/collection_spec.rb spec/mordor/connection_spec.rb spec/mordor/resource_spec.rb spec/spec.opts spec/spec_helper.rb tasks/github-gem.rake)
end

