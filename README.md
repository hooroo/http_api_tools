# Hooroo API Tools
Terribly named, in a rush - if you have a good one, lets change it.

Provides fast serialization/deserialization of models with simple model attribute definition in client apps.

Based on the ID Based Json API Spec - http://jsonapi.org/format/#id-based-json-api

###Why?
We tried using active model serializer and virtus for serialization and model attribute definition/coercion
and found that they both performed inadequately for our needs. At this stage, this gem provides the stuff we
need for a fraction of the performance footprint.

We later discovered Restpack Serializer (https://github.com/RestPack/restpack_serializer) which provides most of what
our serializer does with some differences in it's usage. We haven't done any performance comparisons at this stage.


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

### Deserialization
The `Hat::JsonDeserializer` expects json in the format that the serializer has created making it easy to create matching rest apis and clients with little work needing to be done at each end.

`Hat::JsonDeserializer.new(json).deserialize`

This will iterate over the json, using the attribute names to match types to models in the client app. As long as models exist with names that match the keys in the json, a complete graph of objects will be created upon deserialization, complete with two way relationships when they exist.

In the previous example, the following model classes would be expected:

* User
* Post
* Comment

If keys for relationships are named something that deviates from the name of the class required to build them, this will not currently work.  This should be straight forward to implement however and will be done when the need arises.


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


### Polymorphism
At this point, polymorphic relationships are not catered for but they can be when the need arises.


## Contributing

This gem is currently being used exclusively by Places Api and Places Web. Any changes should be validated against
these applications and have specs written to validate behaviour.

### A note on performance
Performance is critial for this gem so any changes must be made with this in mind. There is a basic performance
spec for serialization that dumps some timings and creates a profile report in `reports/profile_report.html`.

Until we have a more robust way of tracking performance over time, please do some before and after tests against this when you make changes. Even small things have been found to introduce big performance issues.


## To Do
* Support serialization/deserialization of relationships with a key that differs from the type
* Support polymorhic relationships


