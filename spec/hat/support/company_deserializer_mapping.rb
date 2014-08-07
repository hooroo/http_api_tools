# encoding: utf-8

require 'hat/sideloading/json_deserializer_mapping'

class CompanyDeserializerMapping

  include Hat::Sideloading::JsonDeserializerMapping

  map :employees, Person

end