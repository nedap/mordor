require File.join(File.dirname(__FILE__), '..', '/spec_helper.rb')

describe "connecting to mongo" do

  before :each do
    clean_sheet
  end

  it "should have a connection to mongo" do
    @connection.should be_instance_of(Mongo::Connection)
  end

  it "should select the correct database" do
    @db.name.should == Mordor::CONFIG[:database]
  end
end
