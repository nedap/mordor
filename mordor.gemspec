require './lib/mordor/version'

Gem::Specification.new do |s|
  s.name    = 'mordor'

  # Do not set the version and date field manually, this is done by the release script
  s.version = Mordor::VERSION
  s.date    = "2015-05-15"

  s.summary     = 'mordor'
  s.description = <<-eos
    Small gem to add MongoDB Resources, resources have attributes that translate into document fields. When an attribute is declared, finders for the attribute are added to the Resource automatically
  eos

  s.authors  = ['Jan-Willem Koelewijn', 'Dirkjan Bussink']
  s.email    = ['janwillem.koelewijn@nedap.com', 'dirkjan.bussink@nedap.com']
  s.homepage = 'http://www.nedap.com'

  s.add_runtime_dependency 'extlib'
  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'mongo', '< 2.0'

  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rake', '< 11.0'
  s.add_development_dependency 'rspec', '~> 2.0', '< 2.99'

  s.extensions << 'ext/mkrf_conf.rb'

  if defined? JRUBY_VERSION
    s.platform = 'java'
  else
    s.add_runtime_dependency('bson_ext')
  end

  # The files and test_files directives are set automatically by the release script.
  # Do not change them by hand, but make sure to add the files to the git repository.
  s.files = %w(.gitignore .travis.yml CHANGES.md Gemfile Guardfile LICENSE README.md Rakefile ext/mkrf_conf.rb lib/mordor.rb lib/mordor/collection.rb lib/mordor/config.rb lib/mordor/resource.rb lib/mordor/version.rb mordor.gemspec spec/mordor/collection_spec.rb spec/mordor/connection_spec.rb spec/mordor/resource_spec.rb spec/spec.opts spec/spec_helper.rb tasks/github-gem.rake)
end
