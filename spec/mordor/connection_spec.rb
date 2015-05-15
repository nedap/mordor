require File.join(File.dirname(__FILE__), '..', '/spec_helper.rb')

describe "connecting to mongo" do
  before :each do
    class TestResource
      include Mordor::Resource
    end
  end

  describe 'database connection' do
    it "should have a mongo database " do
      TestResource.database.should be_instance_of(Mongo::DB)
    end

    it "should select the correct database" do
      database_name = "any_database_name"
      Mordor::Config.use { |config| config[:database] = database_name }

      TestResource.database.name.should == database_name
    end
  end

  describe "when credentials are provided" do
    let(:credentials) { {:username => "A username", :password => "A password"} }

    before :each do
      Mordor::Config.use do |config|
        config[:username] = credentials[:username]
        config[:password] = credentials[:password]
      end

      @mock_db = double("db")
      Mongo::Connection.stub(:new).and_return(double("connection", :db => @mock_db))
    end

    it "should authenticate with username and password" do
      @mock_db.should_receive(:authenticate).with(credentials[:username], credentials[:password])
      TestResource.database
    end
  end

  describe "the Mongo database connection" do
    before :each do
      @mock_connection = double("connection", :db => double("db"))
    end

    it "should connect with specified host" do
      host = "any host IP or reachable hostname"
      Mordor::Config.use { |config| config[:hostname] = host }

      Mongo::Connection.should_receive(:new).with(host, anything).and_return(@mock_connection)

      TestResource.database
    end

    it "should connect on specified port" do
      port = rand(10000)
      Mordor::Config.use { |config| config[:port] = port }

      Mongo::Connection.should_receive(:new).with(anything, port).and_return(@mock_connection)

      TestResource.database
    end
  end

  describe "replica sets" do
    before :each do
      @mock_connection = double("connection", :db => double("db"))
    end

    after :each do
      TestResource.database
    end

    let(:host_string){ "localhost:27017, localhost:27018  " }
    let(:replica_set_string){ "sample replica set" }

    it "creates a mongo replica set client when multiple hosts are provided" do
      hosts_array = host_string.split(",").map{ |h| h.strip }
      Mordor::Config.use { |config| config[:hostname] = host_string }

      Mongo::MongoReplicaSetClient.should_receive(:new).with(hosts_array, anything).and_return(@mock_connection)
    end

    it "creates a mongo replica set client with the correct replica set name if given" do
      Mordor::Config.use do |config|
        config[:hostname] = host_string
        config[:replica_set] = replica_set_string
      end

      options = {:rs_name => replica_set_string, :refresh_mode => :sync}

      Mongo::MongoReplicaSetClient.should_receive(:new).with(anything, options).and_return(@mock_connection)
    end

    it "creates a mongo replica set client with specific pool size, if given" do
      Mordor::Config.use do |config|
        config[:hostname] = host_string
        config[:pool_size] = 1
      end

      options = {:pool_size => 1, :refresh_mode => :sync}

      Mongo::MongoReplicaSetClient.should_receive(:new).with(anything, options).and_return(@mock_connection)
    end

    it "creates a mongo replica set client with specific pool timeout, if given" do
      Mordor::Config.use do |config|
        config[:hostname] = host_string
        config[:pool_timeout] = 1
      end

      options = {:pool_timeout => 1, :refresh_mode => :sync}

      Mongo::MongoReplicaSetClient.should_receive(:new).with(anything, options).and_return(@mock_connection)
    end

    it "creates a mongo replica set client with specific pool timeout and size" do
      Mordor::Config.use do |config|
        config[:hostname] = host_string
        config[:pool_size] = 5
        config[:pool_timeout] = 1
        config[:replica_set] = replica_set_string
      end

      options = {:pool_size => 5, :pool_timeout => 1, :refresh_mode => :sync, :rs_name => replica_set_string}

      Mongo::MongoReplicaSetClient.should_receive(:new).with(anything, options).and_return(@mock_connection)
    end

  end
end
