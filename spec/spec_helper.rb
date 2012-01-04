require 'rubygems'
require 'mongo'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'mordor'

Mordor::Config[:database] = 'test'

def clean_sheet
  @connection ||= Mongo::Connection.new(Mordor::Config[:hostname], Mordor::Config[:port])
  @db ||= @connection[Mordor::Config[:database]]

  ['TestResource', 'TestTimedResource'].each do |resource|
    if Object.const_defined?(resource)
      @db[Object.const_get(resource).collection_name].drop
    end
  end
end

