# encoding: utf-8

require 'http_api_tools/sideloading/json_deserializer_mapping'

class CompanyDeserializerMapping

  include HttpApiTools::Sideloading::JsonDeserializerMapping

  map :employees, Person

end