# encoding: utf-8

require 'http_api_tools/sideloading/json_deserializer_mapping'

module ForDeserializing
  class CompanyDeserializerMapping

    include HttpApiTools::Sideloading::JsonDeserializerMapping

    map :employees, ForDeserializing::Person

  end
end