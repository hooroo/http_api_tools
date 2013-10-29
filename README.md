# Hooroo API Tools
Named in a rush - if you have a good one, lets change it.

Provides fast serialization/deserialization of models with simple model attribute definition in client apps.

###Why?
We tried using active model serializer and virtus for serialization and model attribute definition/coercion
and found that they both performed quite badly. At this stage, this gem provides the stuff we need for a fraction
of the performance footprint.


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
Serialization is carried out through serializers. There is a one-to-one mapping between a model class and it's corresponding serializer class.

Eg: For a model called `User`, a serializer called `UserSerializer` would automatically be used to serialize instances.

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
By default, only the ids of related objects will be serialized.  Ids are serialized against keys representing the relationship
name with a `_id` or `_ids` suffix.

```javascript
{
 "user": {
    "id": 1,
    "first_name": "John",
    "last_name": "Smith",
    "profile_id": 2,
    "post_ids": [3, 4]
 }
}
```

One advantage to this approach is that it's always clear what relationships exist for a resource. Embedding relationships inside another resource can make it hard to know whether a relationship exists, especially if different requests return the same resource in different ways.

##### Sideloading related resources
Often it will be desirable to sideload the related data to save on requests. This can be done when creating the top level serializer using the same approach ActiveRecord uses for including relationships in queries.

`UserSerializer.new(user).includes(:profile, { posts: [:comments] })`

Which produces the following json:

```javascript
{
 "user": {
    "id": 1,
    "first_name": "John",
    "last_name": "Smith",
    "profile_id": 2,
    "post_ids": [3, 4]
 },
 "profiles": [
  {
    "id": 2,
    //...
  }
 ],

 posts: [
  {
    "id": 3,
    "user_id": 1,
    "comment_ids": [5]
    //...
  },
  {
    "id": 4,
    "user_id": 1,
    "comment_ids": []
    //...
  }
 ],
 "comments": [
  "id": 5,
  "post_id": 3,
  //...
 ]

}
```

Another benefit to sideloading over nesting resources is that if the same resource is referenced multiple times, it only needs to be serialized once.

Note how the root node has a singular key and the related (sideloaded) resources are keyed under their pluralized name.



#### Meta data
Every request will also contain a special meta attribute which could be augmented with various extra meta-data. At this point, it will always return the `type` and `root_key` for the current request.  Eg:

```javascript
{
  "meta": {
    "type": "user",
    "root_key": "user"
  },
  "user": {
    "id": 1,
    "first_name": "John",
    "last_name": "Smith",
    "profile_id": 2,
    "post_ids": [3, 4]
  }
  //Sideloaded data goes here
}
```

If we are returning a collection of items rather than a singular, we'd see the following:

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


### Deserialization
A deserializer exists that expects json in the format the that the serializer has created making it easy to create matching rest apis and clients with little work needing to be done at each end.

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

Until we have a more robust way of tracking performance over time, please do some before and after tests against this when you make changes. Even small things have been found to introduce big performance issues. For example, we do lots of string singularization so we have cached these. We also started using `hash_with_indifferent_access` in the `IdentityMap` and found by removing it we gained significant savings.


