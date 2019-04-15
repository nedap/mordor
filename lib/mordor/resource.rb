module Mordor
  module Resource
    attr_accessor :_id

    def self.included(base)
      base.extend(ClassMethods)
    end

    def initialize(attributes = {})
      attributes.each do |k,v|
        self.send("#{k}=", v)
      end
    end

    def replace_params(params = {})
      result = {}
      return result if params.nil? or params.empty?
      params.each do |key, value|
        value = replace_type(value)
        key = key.to_s.gsub(/\W|\./, "_")
        result[key] = value
      end
      result
    end

    def replace_type(value)
      case value
      when Hash
        value = replace_params(value)
      when Date, DateTime
        value = value.to_time.getlocal
      when Time
        value = value.getlocal
      when BigDecimal
        value = value.to_f
      when Array
        value = value.map do |val|
          replace_type(val)
        end
      when BSON::Timestamp
        value = replace_params({:seconds => value ? value.seconds : 0, :increment => value ? value.increment : 0})
      when Integer
      else
        value = value.to_s
      end
      value
    end

    def new?
      return self._id == nil
    end

    def saved?
      return !new?
    end

    def reload
      return unless _id
      res = self.class.get(_id).to_hash.each do |k, v|
        self.send("#{k}=".to_sym, v)
      end
      self
    end

    def save
      unless self._id
        self_hash = self.to_hash
        if timestamp_attribute = self.class.timestamped_attribute
          timestamp_value = self_hash.delete(timestamp_attribute)
          if timestamp_value.is_a?(Hash)
            timestamp_value = BSON::Timestamp.new(timestamp_value["seconds"], timestamp_value["increment"])
          end
          ordered_self_hash = BSON::OrderedHash.new
          if timestamp_value.nil? || (timestamp_value.is_a?(String) && timestamp_value.empty?)
            ordered_self_hash[timestamp_attribute] = BSON::Timestamp.new(0, 0)
          else
            ordered_self_hash[timestamp_attribute] = timestamp_value
          end
          self_hash.each do |key, value|
            ordered_self_hash[key] = value
          end
          self_hash = ordered_self_hash
        end
        with_collection do |collection|
          insert_id = collection.insert(self_hash)
          self._id = insert_id
        end
      else
        insert_id = self.update
      end
      saved?
    end

    alias_method :save!, :save

    def with_collection
      self.class.with_collection do |collection|
        yield collection
      end
    end

    def update
      insert_id = nil
      with_collection do |collection|
        insert_id = collection.update({:_id => self._id}, self.to_hash)
      end
      insert_id
    end

    def collection
      self.class.collection
    end

    def to_hash
      attributes = self.class.instance_variable_get(:@attributes)
      result = {}
      return result unless attributes
      attributes.each do |attribute_name|
        result[attribute_name] = replace_type(self.send(attribute_name))
      end
      result
    end

    def to_json(*args)
      to_hash.merge(:_id => _id).to_json(*args)
    end

    def destroyed?
      @destroyed ||= false
    end

    def destroy
      collection.remove({:_id => _id})
      self.class.send(:ensure_indices)
      @destroyed = true
    end

    module ClassMethods
      def create(attributes = {})
        resource = self.new(attributes)
        resource.save
        resource
      end

      def all(options = {})
        Collection.new(self, perform_collection_find({}, options))
      end

      def collection
        collection = nil
        with_database do |database|
          collection = database.collection(self.collection_name)
        end
        collection
      end

      def collection_name
        klassname = self.to_s.downcase.gsub(/[\/|.|::]/, '_')
        "#{klassname}s"
      end

      def get(id)
        if id.is_a?(String)
          id = BSON::ObjectId.from_string(id)
        end
        if attributes = perform_collection_find_one(:_id => id)
          new(attributes)
        else
          nil
        end
      end

      def database
        unless @db
          if connecting_to_replica_set?
            client = new_replica_set_client
          else
            client = new_mongo_connection
          end
          @db = database_connection(client)
        end

        @db
      end

      def with_database(max_retries=60)
        retries = 0
        begin
          yield self.database
        rescue Mongo::ConnectionFailure => ex
          retries += 1
          raise ex if retries > max_retries
          sleep(0.5)
          retry
        end
      end

      def with_collection
        with_database do |database|
          yield database.collection(self.collection_name)
        end
      end

      def find_by_id(id)
        get(id)
      end

      def find(query, options = {})
        Collection.new(self, perform_collection_find(query, options))
      end

      def find_by_day(value, options = {})
        if value.is_a?(Hash)
          raise ArgumentError.new(":value missing from complex query hash") unless value.keys.include?(:value)
          day = value.delete(:value)
          query = value.merge(day_to_query(day))
        else
          query = day_to_query(value)
        end

        cursor = perform_collection_find(query, options)
        Collection.new(self, cursor)
      end

      def timestamped_attribute
        @timestamped_attribute
      end

      def attribute(name, options = {})
        @attributes  ||= []
        @indices     ||= []
        @index_types ||= {}

        @attributes << name unless @attributes.include?(name)
        if options[:index]
          @indices    << name unless @indices.include?(name)
          @index_types[name] = options[:index_type] ? options[:index_type] : Mongo::DESCENDING
        end

        if options[:timestamp]
          raise ArgumentError.new("Only one timestamped attribute is allowed, '#{@timestamped_attribute}' is already timestamped") unless @timestamped_attribute.nil?
          @timestamped_attribute = name
        end

        method_name = options.key?(:finder_method) ? options[:finder_method] : "find_by_#{name}"

        class_eval <<-EOS, __FILE__, __LINE__
          attr_accessor name

          def self.#{method_name}(value, options = {})
            if value.is_a?(Hash)
              raise ArgumentError.new(":value missing from complex query hash") unless value.keys.include?(:value)
              query = {:#{name} => value.delete(:value)}
              query = query.merge(value)
            else
              query = {:#{name} => value}
            end
            col = perform_collection_find(query, options)
            Collection.new(self, col)
          end
        EOS
      end

    private

      def perform_collection_find(query, options = {})
        ensure_indices
        collection.find(query, options)
      end

      def perform_collection_find_one(query, options = {})
        ensure_indices
        collection.find_one(query, options)
      end

      def ensure_indices
        indices.each do |index|
          ensure_index(index)
        end
      end

      def ensure_index(attribute)
        with_collection do |collection|
          collection.ensure_index( [ [attribute.to_s, index_types[attribute] ]] )
        end
      end

      def indices
        @indices ||= []
      end

      def index_types
        @index_types ||= {}
      end

      def day_to_range(day)
        case day
        when DateTime
          start = day.to_date.to_time
          end_of_day = (day.to_date + 1).to_time
        when Date
          start = day.to_time
          end_of_day = (day + 1).to_time
        when Time
          start = day.to_datetime.to_date.to_time
          end_of_day = (day.to_datetime + 1).to_date.to_time
        end
        [start, end_of_day]
      end

      def date_range_to_query(range)
        {:at => {:$gte => range.first, :$lt => range.last}}
      end

      def day_to_query(day)
        date_range_to_query( day_to_range(day) )
      end

      # Connection setup

      def new_mongo_connection
        Mongo::Connection.new(*mongo_connection_args)
      end

      def new_replica_set_client
        Mongo::MongoReplicaSetClient.new(*replica_set_client_args)
      end

      def database_connection(client)
        client.db(Mordor::Config[:database]).tap do |db|
          db.authenticate(*authentication_args) if authentication_args.any?
        end
      end

      # Connection arguments

      def mongo_connection_args
        args = [ Mordor::Config[:hostname], Mordor::Config[:port] ]
        args << connection_pool_options if connection_pool_options.any?
        args
      end

      def replica_set_client_args
        [ replica_set_host_list, replica_set_options ]
      end

      def authentication_args
        args = []
        if user_name = Mordor::Config[:username]
          args << user_name
          args << Mordor::Config[:password] if Mordor::Config[:password]
        end
        args
      end

      # Connection options

      def connection_pool_options
        @connection_pool_options ||= Hash.new.tap do |hash|
          hash[:pool_size]    = Mordor::Config[:pool_size]    if Mordor::Config[:pool_size]
          hash[:pool_timeout] = Mordor::Config[:pool_timeout] if Mordor::Config[:pool_timeout]
        end
      end

      def replica_set_options
        @replica_set_options ||= connection_pool_options.tap do |hash|
          hash[:refresh_mode] = Mordor::Config[:rs_refresh_mode]
          hash[:rs_name]      = Mordor::Config[:replica_set] if Mordor::Config[:replica_set]
        end
      end

      # Replica set helpers

      def replica_set_host_list
        @replica_set_hosts ||= Mordor::Config[:hostname].split(',').map(&:strip).compact
      end

      def connecting_to_replica_set?
        replica_set_host_list.size > 1
      end

    end
  end
end
