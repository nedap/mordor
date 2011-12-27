## Introduction
Small library to add DataMapper style resources for MongoDB.

```ruby
class ExampleResource
  include Mordor::Resource

  attribute :first, :index => true
  attribute :second
  attribute :third, :finder_method => :find_by_third_attribute
end
```

This adds attr_accessors to the ExampleResource for each attribute, plus adds finder methods of the form 
`find_by_{attribute}`. The naming convention can be overridden by using the optional `:finder_method` option,
as can be seen with the third attribute.

When the `:index => true` option is set, indices are ensured before each query on 
the collection. Indices are descending by default, but this can be changed by also supplying a `:index_type => Mongo::ASCENDING` option.

We are thinking about adding timestamps on creation as well, this will always be the first field to be inserted, using a Ruby variation of `{ts : new Timestamp()}`. 
This will create BSON Timestamps on the resources, which can help when having some order in the resources is needed. 
