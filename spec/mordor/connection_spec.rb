require File.join(File.dirname(__FILE__), '..', '/spec_helper.rb')

describe "connecting to mongo" do

  before :each do
    clean_sheet
  end

  it "should have a connection to mongo" do
    @connection.should be_instance_of(Mongo::Connection)
  end

  it "should select the correct database" do
    @db.name.should == Mordor::Config[:database]
  end

  it "should be possible to change the configuration" do
    old_db = Mordor::Config[:database]
    Mordor::Config.use do |c|
      c[:database] = 'some_other'
    end

    Mordor::Config[:database].should == 'some_other'
    Mordor::Config[:database] = old_db
  end
end
