require File.join(File.dirname(__FILE__), '..', '/spec_helper.rb')

describe "with respect to collections" do
  class TestResource
    include Mordor::Resource

    attribute :first
    attribute :second
    attribute :third, :finder_method => :find_by_third_attribute
  end

  describe "serialization" do
    before :all do
      clean_sheet

      5.times do |index|
        res = TestResource.new(:first => "#{index}_first", :second => "#{index}_second", :third => "#{index}_third")
        res.save.should be_true
      end
    end

    it "should correctly serialize a collection" do
      collection = TestResource.all
      collection.size.should == 5

      json_collection = collection.to_json
      json_collection.should_not be_nil

      json_collection = JSON.parse(json_collection)

      collection_name = TestResource.collection_name.to_sym.to_s
      json_collection.keys.should include collection_name
      json_collection[collection_name].should_not be_nil
      json_collection[collection_name].should be_a Array
      json_collection[collection_name].size.should == 5
    end
  end
end
