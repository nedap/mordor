require 'rubygems/dependency_installer'

gdi = Gem::DependencyInstaller.new

begin
  if RUBY_PLATFORM == 'java'
    puts "Not installing bson_ext gem, because we're running on JRuby"
  else
    puts "Installing bson_ext"
    gdi.install "bson_ext"
  end
rescue => e
  warn "#{$0}: #{e}"

  exit!
end

# Write fake Rakefile for rake since Makefile isn't used
File.open(File.join(File.dirname(__FILE__), 'Rakefile'), 'w') do |f|
  f.write("task :default" + $/)
end
