module Mordor
  class Collection
    include Enumerable

    def initialize(klass, cursor)
      @klass = klass
      @cursor = cursor
    end

    def to_a
      array = []
      unless @cursor.is_a? Array
        @cursor.each do |element|
          if element.is_a? @klass
            array << element
          else
            array << @klass.new(element)
          end
        end
        @cursor.rewind!
      else
        array = @cursor.dup
      end
      array
    end

    def each
      @cursor.each do |element|
        if element.is_a? @klass
          yield element
        else
          yield @klass.new(element)
        end
      end
      @cursor.rewind! unless @cursor.is_a? Array
    end

    def first
      if @cursor.is_a? Array
        @cursor.first ? @klass.new(@cursor.first) : nil
      else
        result = @cursor.first
        @cursor.rewind!
        result ? @klass.new(result) : nil
      end
    end

    def size
      @cursor.count
    end

    def method_missing(method, *args, &block)
      if @cursor.respond_to?(method)
        self.class.new(@klass, @cursor.__send__(method, *args, &block))
      else
        super
      end
    end

    def to_json
      collection_name = @klass.collection_name.to_sym
      res = {
        collection_name => []
      }
      each do |elem|
        res[collection_name] << elem.to_hash
      end
      res.to_json
    end

    def merge(other_collection)
      Collection.new(@klass, (self.to_a + other_collection.to_a))
    end
    alias_method :+, :merge

    def merge!(other_collection)
      unless @cursor.is_a? Array
        @cursor = @cursor.to_a
      end
      @cursor += other_collection.to_a
    end
  end
end
