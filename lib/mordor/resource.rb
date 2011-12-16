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
      return result unless params
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

    def save
      unless self._id
        insert_id = self.class.collection.insert(self.to_hash)
        self._id = insert_id
      else
        insert_id = self.update
      end
      saved?
    end

    alias_method :save!, :save

    def update
      insert_id = self.class.collection.update({:_id => self._id}, self.to_hash)
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

    module ClassMethods
      def create(attributes = {})
        resource = self.new(attributes)
        resource.save
        resource
      end

      def all(options = {})
        Collection.new(self, collection.find({}, options).to_a)
      end

      def collection
        connection.collection(self.collection_name)
      end

      def collection_name
        klassname = self.to_s.downcase.gsub(/[\/|.|::]/, '_')
        "#{klassname}s"
      end

      def get(id)
        if id.is_a?(String)
          id = BSON::ObjectId.from_string(id)
        end
        if attributes = collection.find_one(:_id => id)
          new(attributes)
        else
          nil
        end
      end

      def connection
        @connection ||= Mordor.connection
      end

      def find_by_id(id)
        get(id)
      end

      def find(query, options = {})
        Collection.new(self, collection.find(query, options).to_a)
      end

      def find_by_day(day, options = {})
        case day
        when DateTime
          start = day.to_date.to_time
          end_of_day = (day.to_date + 1).to_time
        when Date
          start = day.to_time
          end_of_day = (day + 1).to_time
        when Time
          start = day.to_datetime.to_date.to_time
          end_of_day = (day.to_date + 1).to_datetime.to_date.to_time
        end
        hash = {:at => {'$gte' => start, '$lt' => end_of_day}}
        if options.keys.include?(:limit)
          cursor = collection.find({:at => {'$gte' => start, '$lt' => end_of_day}}, options).to_a
        else
          cursor = collection.find({:at => {'$gte' => start, '$lt' => end_of_day}})
        end
        Collection.new(self, cursor)
      end

      def attribute(name, options = {})
        @attributes ||= []
        @attributes << name unless @attributes.include?(name)

        method_name = options.key?(:finder_method) ? options[:finder_method] : "find_by_#{name}"


        class_eval <<-EOS, __FILE__, __LINE__
          attr_accessor name

          def self.#{method_name}(value, options = {})
            if options.keys.include?(:limit)
              col = collection.find({:#{name} => value}, options).to_a
            else
              col = collection.find(:#{name} => value)
            end
            Collection.new(self, col)
          end
        EOS
      end
    end
  end
end
