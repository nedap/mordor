require File.join(File.dirname(__FILE__), '..', '/spec_helper.rb')

describe "connecting to mongo" do
  before :each do
    class TestResource
      include Mordor::Resource
    end
  end

  it "should have a mongo database " do
    TestResource.database.should be_instance_of(Mongo::DB)
  end

  it "should select the correct database" do
    database_name = "any_database_name"
    Mordor::Config.use { |config| config[:database] = database_name }

    TestResource.database.name.should == database_name
  end

  describe "when credentials are provided" do
    let(:credentials) { {:username => "A username", :password => "A password"} }

    before :each do
      Mordor::Config.use do |config|
        config[:username] = credentials[:username]
        config[:password] = credentials[:password]
      end

      @mock_db = mock("db")
      Mongo::Connection.stub(:new).and_return(mock("connection", :db => @mock_db))
    end

    it "should authenticate with username and password" do
      @mock_db.should_receive(:authenticate).with(credentials[:username], credentials[:password])
      TestResource.database
    end
  end

  describe "the Mongo database connection" do
    before :each do
      @mock_connection = mock("connection", :db => mock("db"))
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
      @mock_connection = mock("connection", :db => mock("db"))
    end

    it "creates a mongo replica set client when multiple hosts are provided" do
      hosts = "localhost:27017, localhost:27018  "
      hosts_array = hosts.split(",").map{ |h| h.strip }

      Mordor::Config.use { |config| config[:hostname] = hosts }

      Mongo::MongoReplicaSetClient.should_receive(:new).with(hosts_array, anything).and_return(@mock_connection)

      TestResource.database
    end

    it "creates a mongo replica set client with the correct replica set name if given" do
      hosts = "localhost:27017, localhost:27018  "
      replica_set = "sample replica set"

      Mordor::Config.use do |config|
        config[:hostname] = hosts
        config[:replica_set] = replica_set
      end

      options = {:rs_name => replica_set, :refresh_mode => true}

      Mongo::MongoReplicaSetClient.should_receive(:new).with(anything, options).and_return(@mock_connection)

      TestResource.database
    end
  end
end
