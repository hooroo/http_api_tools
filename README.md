# Http API Tools

Provides fast serialization/deserialization of models with simple model attribute definition in client apps.

Adheres to the ID Based Json API Spec - http://jsonapi.org/format/#id-based-json-api for serialization

## Installation

Add this line to your application's Gemfile:

    gem 'hat'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hat

## Usage
At a high level this gem provides serialization of models (active model or otherwise), deserialization of the serialized json and a way to declaritively create basic models in clients with basic type coercion.

It has been written to work as a whole where the producer and client of the api are both maintained by the same development team. Conventions are used throughout to keep things simple. At this stage, breaking these conventions isn't supported in many cases but the gem can be extended towards this goal as the needs arise. Please see the note on performance in the section on contributing at the end of this document.

### Serialization
There is an intentional one-to-one mapping between a model class and it's corresponding serializer class.

Eg: For a model called `User`, a serializer called `UserSerializer` would automatically be used to serialize instances.

The intention is that a resource should always be represented in the same way as returning different representations for different scenarios only causes confusion. If the same data needs to be represented using various resources, that's ok, they should however be different resources with different names and different urls.

To use a serializer in a controller you should instantiate an instance of the serializer for the top level type you're serializing and pass it to render:

`render json: UserSerializer.new(user)`

#### Serializer Definition

Serializers can define attributes to be serialized and relationships.

```ruby
class UserSerializer

  include Hat::JsonSerializer

  attributes :id, :first_name, :last_name
  has_many :posts
  has_one :profile

end
```

If you want to serialize any composite attributes they can be defined as a method on the serializer and defined as an attribute. The object being serialized can be accessed via the `serializable` method on the serializer.

```ruby
class UserSerializer

  include Hat::JsonSerializer

  attributes :id, :first_name, :last_name, :full_name

  def full_name
    "#{serializable.first_name} #{serializable.last_name}"
  end

end
```

#### JSON Structure

Serialization is structured using a 'sideloading' approach for relationships between the serialized data.
By default, only the ids of related objects will be serialized. These relationships and their ids will be
added to the `links` hash.

```javascript
{
 "users": [{
    "id": 1,
    "first_name": "John",
    "last_name": "Smith",
    "links" {
      "profile": 2,
      "posts": [3, 4]
    }
 }]
}
```

One advantage to this approach is that it's always clear what relationships exist for a resource, even if you don't
include the resources themselves in the response. Embedding relationships inside another resource can make it hard
to know whether a relationship exists, especially if different requests return the same resource in different ways.

##### Sideloading related resources
Often it will be desirable to sideload the related data to save on requests. This can be done when creating the top level serializer using the same approach ActiveRecord uses for including relationships in queries.

`UserSerializer.new(user).includes(:profile, { posts: [:comments] })`

Which produces the following json:

```javascript
{
 "users": [{
    "id": 1,
    "first_name": "John",
    "last_name": "Smith",
    "links": {
      "profile": 2,
      "posts": [3, 4]
    }
 }],
 "linked": {
   "profiles": [
    {
      "id": 2,
      //...
    }
   ],

   posts: [
    {
      "id": 3,
      "links": {
        "user": 1,
        "comments": [5]
      }
      //...
    },
    {
      "id": 4,
      "links": {
        "user": 1,
        "comments": []
      }
      //...
    }
   ],
   "comments": [
    "id": 5,
    "links": {
        "post": 3
    }
    //...
   ]
  }

}
```

Another benefit to sideloading over nesting resources is that if the same resource is referenced multiple times, it only needs to be serialized once.

##### Url based sideloading
It's possible to determine what resources to sideload by providing a query string parameter:

`http://example.com/users/1?include?comments,posts.comments`

This can be parsed using:

`relation_includes = Hat::RelationIncludes.from_params(params)`

and splat into the serializer includes:

`UserSerializer.new(user).includes(*relation_includes)`

and/or active record queries:

`User.find(params[:id]).includes(*relation_includes.for_query_on(User))`

When providing the includes for an active record query, we actually want a deeper set of includes in order to account for the ids fetched for has_many relationships. If we simplify passed the same set of includes to the query as we pass to the serializer, we'd end up with n+1 problems when fetching the ids for the has_many relationships.

Calling `relation_includes.for_query_on(User)` will figure out the minimum set of includes that are required based on:

* The models and their relationships
* The relationships actually being serialized

##### Restricting what is included
Once you open up what is sideload as a query string parameter you risk DOS attacks or poorly considered api calls that fetch too much. This can be countered by defining what is `includable` for each serializer what it's being used as the root serializer for a json response.

```ruby
class UserSerializer

  include Hat::JsonSerializer

  attributes :id, :first_name, :last_name, :full_name

  has_many :posts
  has_many :comments

  includable(:profile, {:posts, [:comments]})

end
```

This will ensure that regardless of what is declared in the `include` param, no more than the allowable includes are ever returned.

To help in documenting what is includable, both the includable and included relations are returned in the meta data of the response.

```javascript
"meta": {
  "type": "user",
  "root_key": "users",
  "includable": "profile,posts,posts.comments"
  "included": "posts"
}
```

#### Meta data
Every request will also contain a special meta attribute which could be augmented with various additional pieces
of meta-data. At this point, it will always return the `type` and `root_key` for the current request.  Eg:

```javascript
{
  "meta": {
    "type": "user",
    "root_key": "users"
  },
  "users": [{
    "id": 1,
    "first_name": "John",
    "last_name": "Smith",
    "profile_id": 2,
    "post_ids": [3, 4]
  }]
  //Sideloaded data goes here
}
```

Notice that the root is an array and the root_key a plural. This is the case regardless of whether a single resource
is being represented or a collection of resources. This is in line with the json-api spec and generally simplifies both serialization and deserialization.

##### Adding Metadata
It might be desirable to add extra metadata to the serialized response. For example, adding information such as limit, offset, what includes are valid etc can be helpful to a client.

`UserSerializer.new(user).meta(limit: 10, offset: 0)`

### Deserialization
The `Hat::JsonDeserializer` expects json in the format that the serializer has created making it easy to create matching rest apis and clients with little work needing to be done at each end.

`Hat::JsonDeserializer.new(json).deserialize`

This will iterate over the json, using the attribute names to match types to models in the client app. As long as models exist with names that match the keys in the json, a complete graph of objects will be created upon deserialization, complete with two way relationships when they exist.

In the previous example, the following model classes would be expected:

* User
* Post
* Comment

#### Deserializer Mappings

At times, the name of an object's key may deviate from it's type and can't be deserialized by convention alone.

```javascript
{
 "users": [{
    "id": 1,
    "first_name": "John",
    "last_name": "Smith",
    "links": {
      "posts": [3]
    }
 }],
 "linked": {
   posts: [
    {
      "id": 3,
      "links": {
        "author": 1
      }
    }
  }
}
```

In this example, the `user` is the `author` of the `post`. It is impossible to infer from the data that an `author` attribute key should map to a `User` type so we need to give it a helping hand. This can be done once per type by creating a `JsonDeserializerMapping` class. Like with serializers, deserializer mappings are convention based, using the model class name as a prefix.

```ruby
class PostDeserializerMapping

  include Hat::JsonDeserializerMapping

  map :author, User

end
```

Whenever we're deserializing a `post`, the `author` attribute will always be deserialized to an instance of a `User`.

This can also be applied against collections:

```ruby
class CompanyDeserializerMapping

  include Hat::JsonDeserializerMapping

  map :employees, Person

end
```

### Models
Client models have some basic requirements that are catered to such as attribute definition, default values and type coercion.

For example:

```ruby
class User

  include Hat::Model::Attributes
  include Hat::Model::ActsLikeActiveModel

  attribute :id
  attribute :first_name
  attribute :last_name
  attribute :created_at: type: :date_time
  attribute :posts, default: []
  attribute :profile

end
```

This will define a User class with attr_accessors for all attributes defined. The initialize method will accept a hash of values which will be passed through type coercions when configured and have defaults applied when no value is passed in for a key.

At this stage type coercion is limited and there's no way to define types outside the gem. This will change when the need arises or we get around to it. For now if a type coercion makes sense to add for all apps, it should be added to `type_coercions.rb`.
See: https://github.com/hooroo/hooroo-api-tools/issues/5

#### Read only attributes
Sometimes it's useful to define a field as readonly. The intent being that we prevent changing an attribute value that shouldn't be changed or prevent a value from being serialized and sent in the payload that the server won't accept.

In the previous example, it might be better to set the `created_at` field as readonly:

```ruby
class User

  include Hat::Model::Attributes
  include Hat::Model::ActsLikeActiveModel

  attribute :id
  attribute :first_name
  attribute :last_name
  attribute :created_at: type: :date_time, read_only: true
  attribute :posts, default: []
  attribute :profile

end
```

### Polymorphism
At this point, polymorphic relationships are not catered for but they can be when the need arises.


## Contributing

### A note on performance
Performance is critial for this gem so any changes must be made with this in mind. There is a basic performance
spec for serialization that dumps some timings and creates a profile report in `reports/profile_report.html`.

Until we have a more robust way of tracking performance over time, please do some before and after tests against this when you make changes. Even small things have been found to introduce big performance issues.


## To Do
* Support polymorhic relationships
* Support the Json Api UPDATES spec



