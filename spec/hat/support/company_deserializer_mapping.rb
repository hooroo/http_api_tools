require 'hat/json_deserializer_mapping'

class CompanyDeserializerMapping

  include Hat::JsonDeserializerMapping

  map :employees, Person

end