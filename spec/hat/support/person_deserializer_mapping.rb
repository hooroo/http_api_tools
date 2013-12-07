require 'hat/json_deserializer_mapping'

class PersonDeserializerMapping

  include Hat::JsonDeserializerMapping

  map :employer, Company

end