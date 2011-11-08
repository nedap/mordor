require 'rubygems'
require 'mongo'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'mordor'

module Auditing
CONFIG = {
  :hostname => 'localhost',
  :port     =>  27017,
  :database => 'test'
}
end

def clean_sheet
  @connection ||= Mongo::Connection.new(Mordor::CONFIG[:hostname], Mordor::CONFIG[:port])
  @db ||= @connection[Mordor::CONFIG[:database]]
  if Object.const_defined?('TestResource')
    @db[TestResource.collection_name].drop
  end
end

