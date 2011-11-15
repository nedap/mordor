require 'rubygems'
require 'mongo'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'mordor'

module Mordor
CONFIG = {
  :hostname => 'localhost',
  :port     =>  27017,
  :database => 'test'
}
end

def clean_sheet
  @connection ||= Mongo::Connection.new(Mordor::CONFIG[:hostname], Mordor::CONFIG[:port])
  @db ||= @connection[Mordor::CONFIG[:database]]

  ['TestResource', 'TestTimedResource'].each do |resource|
    if Object.const_defined?(resource)
      @db[Object.const_get(resource).collection_name].drop
    end
  end
end

