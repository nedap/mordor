## Introduction
Small library to add DataMapper style resources for MongoDB.

```ruby
class ExampleResource
  include Mordor::Resource

  attribute :first, :index => true
  attribute :second
  attribute :third, :finder_method => :find_by_third_attribute
  attribute :at,    :timestamp => true
end
```

This adds attr_accessors to the ExampleResource for each attribute, plus adds finder methods of the form 
`find_by_{attribute}`. The naming convention can be overridden by using the optional `:finder_method` option,
as can be seen with the third attribute.

When the `:index => true` option is set, indices are ensured before each query on 
the collection. Indices are descending by default, but this can be changed by also supplying a `:index_type => Mongo::ASCENDING` option.

At most one attribute per Resource can have the option `:timestamp => true` set. This means that the attribute will be saved as one of the two first 
attributes (the other one being the `_id` attribute. When no value is given for the timestamped attribute, a timestamp with value 0 will be inserted,
which results in a timestamp being assigned to it by the MongoDB.
An exception is raised when more than one attribute is given the timestamp option
