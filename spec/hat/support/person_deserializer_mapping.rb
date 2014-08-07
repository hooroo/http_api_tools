require 'hat/sideloading/json_deserializer_mapping'

class PersonDeserializerMapping

  include Hat::Sideloading::JsonDeserializerMapping

  map :employer, Company

end