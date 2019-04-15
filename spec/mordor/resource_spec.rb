require File.join(File.dirname(__FILE__), '..', '/spec_helper.rb')

describe "with respect to resources" do
  before :each do
    class TestResource
      include Mordor::Resource

      attribute :first,  :index => true
      attribute :second, :index => true, :index_type => Mongo::ASCENDING
      attribute :third,  :finder_method => :find_by_third_attribute
      attribute :at
      attribute :created_at,     :timestamp => true

      # Put this in here again to ensure the original method is still here
      class_eval do
        def self.ensure_indices
          collection.ensure_index( indices.map{|index| [index.to_s, Mongo::DESCENDING]} ) if indices.any?
        end
      end
    end
  end

  after :each do
    drop_db_collections
  end

  it "should create accessor methods for all attributes" do
    ["first", "first=", "second", "second="].each{ |v| TestResource.public_instance_methods.map{|m| m.to_s}.should include(v) }
  end

  it "should create class level finder methods for all attributes" do
    ["find_by_first", "find_by_second"].each do |finder_method|
      TestResource.methods.map{|m| m.to_s}.should include(finder_method)
    end
  end

  it "should create finder methods with the supplied finder method name" do
    TestResource.methods.map{|m| m.to_s}.should include "find_by_third_attribute"
  end

  it "should ensure indices when the option :index => true is given" do
    TestResource.send(:indices).should include :first
  end

  it "should default to descending indices" do
    TestResource.send(:index_types).keys.should include :first
    TestResource.send(:index_types)[:first].should == Mongo::DESCENDING
  end

  it "should be possible to set index type using the 'index_type' option" do
    TestResource.send(:index_types).keys.should include :second
    TestResource.send(:index_types)[:second].should == Mongo::ASCENDING
  end

  it "should be possible to designate an attribute as a timestamp" do
    TestResource.timestamped_attribute.should_not be_nil
    TestResource.timestamped_attribute.should == :created_at
  end

  it "should only be possible to have one attribute as a timestamp" do
    lambda {
      TestResource2.class_eval do
        attribute :some_timestamp, :timestamp => true
        attribute :another_timestamp, :timestamp => true
      end
    }.should raise_error
  end

  it "should provide timestamped attribute as first attribute when creating a Resource" do
    tr = TestResource.create({:first => 'first'})
    tr.reload
    tr.at.should_not be_nil
    TestResource.get(tr._id).at.should_not == BSON::Timestamp.new(0,0)
  end

  context "with respect to replacing params" do
    it "should correctly substitute non-alphanumeric characters in keys with underscores" do
      options = {
        "o*p#t>i_o@n)s" => "test"
      }
      result = TestResource.new.replace_params(options)
      result.keys.first.should eql "o_p_t_i_o_n_s"
    end

    it "should correctly replace Date and DateTimes" do
      options = {
        "option" => Date.today,
        "another" => DateTime.now
      }
      result = TestResource.new.replace_params(options)
      result.each do |k, v|
        v.should be_a Time
      end
    end

    it "should correctly replace BigDecimals" do
      options = {
        "option" => BigDecimal.new("1.00")
      }
      result = TestResource.new.replace_params(options)
      result.each do |k,v|
        v.should be_a Float
      end
    end

    it "should correctly replace BSON::Timestamps" do
      options = {
        "option" => BSON::Timestamp.new(324244, 12)
      }
      result = TestResource.new.replace_params(options)
      result.each do |k, v|
        v["seconds"].should == 324244
        v["increment"].should == 12
      end
    end

    it "should correctly respond to to_hash" do
      resource = TestResource.new({:first => "first", :second => "second", :third => "third"})
      hash = resource.to_hash
      hash.size.should     == 5
      hash[:first].should  == "first"
      hash[:second].should == "second"
      hash[:third].should  == "third"
      hash[:at].should     == ""
    end
  end

  context "with respect to times and ranges" do
    context "when DateTime days are given" do
      it "should return a correct range" do
        day = DateTime.civil(2012, 1, 19, 10, 0)
        range = TestResource.send(:day_to_range, day)
        range.first.should == DateTime.civil(2012, 1, 19).to_time.gmtime
        range.last.should  == DateTime.civil(2012, 1, 20).to_time.gmtime
      end

      it "should return an Array of 2 Time objects" do
        day = DateTime.civil(2012, 1, 19, 10, 0)
        range = TestResource.send(:day_to_range, day)
        range.first.should be_a Time
        range.last.should be_a Time
      end
    end

    context "when Date days are given" do
      it "should return a correct range" do
        day = Date.parse("2012-1-19")
        range = TestResource.send(:day_to_range, day)
        range.first.should == Date.parse("2012-1-19").to_time.gmtime
        range.last.should  == Date.parse("2012-1-20").to_time.gmtime
      end

      it "should return an Array of 2 Time objects" do
        day = Date.parse("2012-1-19")
        range = TestResource.send(:day_to_range, day)
        range.first.should be_a Time
        range.last.should be_a Time
      end
    end

    context "when Time days are given" do
      it "should return a correct range" do
        day = DateTime.civil(2012, 1, 19, 10, 0).to_time
        range = TestResource.send(:day_to_range, day)
        range.first.should == DateTime.civil(2012, 1, 19).to_time.gmtime
        range.last.should  == DateTime.civil(2012, 1, 20).to_time.gmtime
      end

      it "should return an Array of 2 Time objects" do
        day = DateTime.civil(2012, 1, 19, 10, 0).to_time
        range = TestResource.send(:day_to_range, day)
        range.first.should be_a Time
        range.last.should be_a Time
      end
    end

    context "when ranges are changed to queries" do
      before :each do
        @range = TestResource.send(:day_to_range, DateTime.civil(2012, 1, 19))
        @query = TestResource.send(:date_range_to_query, @range)
      end

      it "should scope the query to the 'at' attribute" do
        @query.size.should == 1
        @query[:at].should be_a Hash
      end

      it "should use the first of the range for the greater equal part" do
        @query[:at][:$gte].should == @range.first
      end

      it "should use the last of the range for the smaller than part" do
        @query[:at][:$lt].should == @range.last
      end
    end
  end

  context "with respect to indices" do
    before :each do
      class TestResource2
        include Mordor::Resource
      end

      [TestResource, TestResource2].each do |klass|
        klass.class_eval do
          def self.reset_ensure_count
            @count = 0
          end

          def self.ensure_count
            @count ||= 0
          end

          def self.ensure_count=(val)
            @count = val
          end

          private

          def self.do_ensure_index(attribute)
            collection.ensure_index( [ [attribute.to_s, index_types[attribute]] ] )
          end

          def self.ensure_indices
            indices.each do |index|
              ensure_index(index)
            end
          end

          def self.ensure_index(attribute)
            self.ensure_count += 1
            self.do_ensure_index(attribute)
          end
        end
      end
    end

    it "should call ensure_index on the collection for each index when a query is performed" do
      TestResource.create({:first => 'first', :second => 'second', :third => 'third'})
      TestResource.reset_ensure_count
      TestResource.all()
      TestResource.ensure_count.should == 2  # For each index
    end

    it "should call ensure_index on the collection whenever a resource is destroyed" do
      resource = TestResource.create({:first => 'first', :second => 'second', :third => 'third'})
      TestResource.reset_ensure_count
      resource.destroy
      TestResource.ensure_count.should == 2  # For each index
    end

    it "should not call ensure index for each index attribute on file eval" do
      TestResource2.class_eval do
        attribute :test_attribute, :index => true
      end

      TestResource2.ensure_count.should == 0
    end
  end

  context "with respect to creating" do
    before :each do
      @resource = TestResource.create({:first => "first", :second => "second", :third => "third"})
    end

    it "should be possible to create a resource" do
      @resource.should be_saved
    end

    it "should be possible to retrieve created resources" do
      res = TestResource.get(@resource._id)
      res.should_not be_nil
      res.first.should eql @resource.first
      res.second.should eql @resource.second
      res.third.should eql @resource.third
      res._id.should eql @resource._id
    end
  end

  context "with respect to destroying" do
    before :each do
      @resource = TestResource.create({:first => "first", :second => "second", :third => "third"})
    end

    it "should not create destroyed resources" do
      @resource.should_not be_destroyed
    end

    it "should be possible to destroy a resource" do
      @resource.should_not be_destroyed
      @resource.destroy
      @resource.should be_destroyed
    end

    it "should not be possible to retrieve a resource after it has been destroyed" do
      @resource.destroy
      res = TestResource.get(@resource._id)
      res.should be_nil
    end

    it "should only destroy the current resource" do
      resource2 = TestResource.create({:first => "first2", :second => "second2", :third => "third2"})
      @resource.destroy
      TestResource.get(resource2._id).should_not be_nil
    end
  end

  context "with respect to saving and retrieving" do
    it "should correctly save resources" do
      resource = TestResource.new({:first => "first", :second => "second"})
      resource.save.should be_true
      resource._id.should_not be_nil
      resource.collection.count.should == 1
      resource.collection.find_one['_id'].should == resource._id
    end

    it "should correctly update resources" do
      resource = TestResource.new({:first => "first", :second => "second"})
      resource.save.should be_true
      resource._id.should_not be_nil

      original_id = resource._id

      resource.collection.count.should == 1
      resource.collection.find_one['_id'].should == resource._id

      resource.first = "third"
      resource.save.should be_true
      resource._id.should == original_id
      resource.collection.find_one['first'].should == resource.first
    end

    it "should be able to find resources by their ids" do
      resource = TestResource.new({:first => "first", :second => "second"})
      resource.save.should be_true
      res = TestResource.find_by_id(resource._id)
      res._id.should    == resource._id
      res.first.should  == resource.first
      res.second.should == resource.second
    end

    it "should be able to find resources by their ids as strings" do
      resource = TestResource.new({:first => "first", :second => "second"})
      resource.save.should be_true
      res = TestResource.find_by_id(resource._id.to_s)
      res._id.should    == resource._id
      res.first.should  == resource.first
      res.second.should == resource.second
    end

    it "should be possible to find resources using queries" do
      resource = TestResource.new({:first => "first", :second => "second"})
      resource.save.should be_true

      resource2 = TestResource.new({:first => "first", :second => "2nd"})
      resource2.save.should be_true

      collection = TestResource.find({:first => "first"})
      collection.should_not be_nil
      collection.size.should == 2

      collection = TestResource.find({:second => "2nd"})
      collection.should_not be_nil
      collection.size.should == 1
    end

    it "should be possible to query with a limit" do
      resource = TestResource.new({:first => "first", :second => "second"})
      resource.save.should be_true

      resource2 = TestResource.new({:first => "first", :second => "2nd"})
      resource2.save.should be_true

      collection = TestResource.find({:first => "first"}, :limit => 1)
      collection.should_not be_nil
      collection.size.should == 1
    end

    it "should be possible to retrieve all resources" do
      TestResource.all.should_not be_nil
      TestResource.all.size.should == 0

      resource = TestResource.new({:first => "first", :second => "second"})
      resource.save.should be_true

      resource2 = TestResource.new({:first => "first", :second => "second"})
      resource2.save.should be_true

      collection = TestResource.all
      collection.should_not be_nil
      collection.size.should == 2
    end

    it "should be possible to limit the number of returned resources" do
      TestResource.all.should_not be_nil
      TestResource.all.size.should == 0

      resource = TestResource.new({:first => "first", :second => "second"})
      resource.save.should be_true

      resource2 = TestResource.new({:first => "first", :second => "second"})
      resource2.save.should be_true

      collection = TestResource.all(:limit => 1)
      collection.should_not be_nil
      collection.size.should == 1
    end

    describe "with respect to passing extra query parameters to finder methods" do
      before :each do
        5.times do |i|
          TestResource.create({:first => "first", :second => "second-#{i}", :third => "third-#{i}", :at => (Date.today).to_time})
        end
      end

      it "should raise an argument exception if the :value option is omitted from a complex finder query" do
        collection = TestResource.find_by_first("first")
        collection.size.should == 5

        lambda{ TestResource.find_by_first({:second => "second-2"})}.should raise_error
      end

      it "should be possible to add extra query clauses to the find_by_day method" do
        collection = TestResource.find_by_day(Date.today)
        collection.size.should == 5

        collection = TestResource.find_by_day({:value => Date.today, :second => "second-1"})
        collection.size.should == 1
        resource = collection.first
        resource.first.should == "first"
        resource.at.should == Date.today.to_time
      end

      it "should be possible to add more complex query clauses to the find_by_day method" do
        collection = TestResource.find_by_day(Date.today)
        collection.size.should == 5

        collection = TestResource.find_by_day({:value => Date.today, :second => {:$in => ["second-1", "second-2"]}})
        collection.size.should == 2
        collection.each do |res|
          res.at.should == Date.today.to_time
          ["second-1", "second-2"].should include res.second
        end

      end

      it "should be possible to add extra query clauses to a finder method" do
        collection = TestResource.find_by_first("first")
        collection.size.should == 5

        collection = TestResource.find_by_first({:value => "first", :second => "second-2"})
        collection.size.should == 1
        resource = collection.first
        resource.first.should == "first"
        resource.second.should == "second-2"
      end

      it "should be possible to add more complex query clauses to a finder method" do
        collection = TestResource.find_by_first("first")
        collection.size.should == 5

        collection = TestResource.find_by_first({:value => "first", :second => {:$in => ["second-1", "second-2"]}})
        collection.size.should == 2
        collection.each do |res|
          res.first.should == "first"
          ["second-1", "second-2"].should include res.second
        end
      end
    end
  end

  context "with respect to retrieving by day" do
    before :each do
      class TestTimedResource
        include Mordor::Resource

        attribute :first
        attribute :at
      end
    end

    it "should be possible to retrieve a Resource by day" do
      TestTimedResource.create({:first => "hallo", :at => DateTime.civil(2011, 11, 11, 11, 11)})

      col = TestTimedResource.find_by_day(DateTime.civil(2011,11,11))
      col.size.should == 1
      col.first.first.should eql "hallo"
    end

    it "should not retrieve resources from other days" do
      TestTimedResource.create({:first => "hallo", :at => DateTime.civil(2011, 11, 11, 11, 11)})

      col = TestTimedResource.find_by_day(DateTime.civil(2011,11,10))
      col.size.should == 0
    end
 end

  context "with respect to collections" do
    it "should correctly return a collection name" do
      TestResource.collection_name.should == "testresources"
    end

    it "should be connected to a database" do
      TestResource.database.should_not be_nil
    end
  end

  context "with respect to not finding something" do
    it "should just return an empty collection when a collection query doesn't return results" do
      col = TestResource.find_by_day(DateTime.civil(2011, 11, 8))
      col.size.should == 0
    end

    it "should return nil when an non existing id is queried" do
      resource = TestResource.find_by_id('4eb8f3570e02e10cce000002')
      resource.should be_nil
    end
  end
end
