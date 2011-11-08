module Mordor
  class Collection
    include Enumerable

    def initialize(klass, cursor)
      @klass = klass
      @cursor = cursor
    end

    def each
      @cursor.each do |element|
        if element
          yield @klass.new(element)
        else
          next
        end
      end
    end

    def first
      result = @cursor.first
      @cursor.rewind!
      result ? @klass.new(result) : nil
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
  end
end
