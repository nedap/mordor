require 'rubygems'
require 'mongo'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'mordor'

RSpec.configure do |config|
  config.before :each do
    reset_mordor_config
  end

  config.after :each do
    remove_class_constants
  end
end

def reset_mordor_config
  Mordor::Config.use do |config|
    config[:username] = nil
    config[:password] = nil
    config[:hostname] = '127.0.0.1'
    config[:port] = 27017
    config[:database] = 'test'
  end
end

def drop_db_collections
  connection = Mongo::Connection.new(Mordor::Config[:hostname], Mordor::Config[:port])
  db = connection[Mordor::Config[:database]]

  test_class_names.each do |resource|
    if Object.const_defined?(resource)
      db[Object.const_get(resource).collection_name].remove
      db[Object.const_get(resource).collection_name].drop
    end
  end
end

def remove_class_constants
  test_class_names.each do |resource_class|
    Object.send(:remove_const, resource_class) if Object.const_defined?(resource_class)
  end
end

def test_class_names
  [:TestResource, :TestResource2, :TestTimedResource]
end
