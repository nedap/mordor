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

  describe "converting to array" do
    before :all do
      clean_sheet

      5.times do |index|
        res = TestResource.new(:first => "#{index}_first", :second => "#{index}_second", :third => "#{index}_third")
        res.save.should be_true
      end
    end

    it "should be possible to convert a collection to an array" do
      collection = TestResource.all
      collection.to_a.should be_a Array
    end

    it "should be possible to convert a collection to an array multiple times" do
      collection = TestResource.all
      array1 = collection.to_a
      array2 = collection.to_a
      array1.size.should == array2.size
    end

    it "should convert the collection to an array with the same size" do
      collection = TestResource.all
      collection_size = collection.size
      collection.to_a.size.should == collection_size
    end
  end

  describe "merging array based collection" do
    before :each do
      @first_collection  = Mordor::Collection.new(TestResource, [TestResource.new(:first => "first", :second => "second", :third => "third")])
      @second_collection = Mordor::Collection.new(TestResource, [TestResource.new(:first => "1st", :second => "2nd", :third => "3rd")])
    end

    it "should not change original collections when no bang is used" do
      first_size = @first_collection.size
      second_size = @second_collection.size

      new_collection = @first_collection.merge(@second_collection)
      @first_collection.size.should == first_size
      @second_collection.size.should == second_size
    end

    it "should create collection with all elements from original collections" do
      new_collection = @first_collection.merge(@second_collection)
      new_collection.size.should == (@first_collection.size + @second_collection.size)

      [@first_collection, @second_collection].each do |collection|
        collection.each do |element|
          new_collection.should include element
        end
      end
    end

    it "should be possible to use the + as an alias" do
      new_collection = @first_collection + @second_collection
      new_collection.size.should == (@first_collection.size + @second_collection.size)

      [@first_collection, @second_collection].each do |collection|
        collection.each do |element|
          new_collection.should include element
        end
      end
    end

    it "should change the receiver of the merge! to have all elements" do
      first_size = @first_collection.size
      second_size = @second_collection.size

      @first_collection.merge!(@second_collection)
      @first_collection.size.should == (first_size + second_size)

      @second_collection.each do |element|
        @first_collection.should include element
      end
    end
  end
end
