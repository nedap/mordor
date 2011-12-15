module Mordor
  class Collection
    include Enumerable

    def initialize(klass, cursor)
      @klass = klass
      @cursor = cursor
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


    def to_json(*args)
      to_a.to_json(*args)
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
