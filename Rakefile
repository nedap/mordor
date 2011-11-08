load('tasks/github-gem.rake')

# Register the gem release tasks in the gem namespace
GithubGem::RakeTasks.new(:gem) do |config|

  # Note that the following values are all default values and can 
  # therefore be omitted if they are not changed.

  config.gemspec_file   = GithubGem.detect_gemspec_file
  config.main_include   = GithubGem.detect_main_include
  config.root_dir       = Dir.pwd
  config.test_pattern   = 'test/**/*_test.rb'
  config.spec_pattern   = 'spec/**/*_spec.rb'
  config.local_branch   = 'master'
  config.remote         = 'origin'
  config.remote_branch  = 'master'
end
