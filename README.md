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
the collection. At the moment all indices are descending. Support for options is in the works
