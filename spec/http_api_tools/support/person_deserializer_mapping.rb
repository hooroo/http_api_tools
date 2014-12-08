require 'http_api_tools/sideloading/json_deserializer_mapping'

module ForDeserializing
  class PersonDeserializerMapping

    include HttpApiTools::Sideloading::JsonDeserializerMapping

    map :employer, ForDeserializing::Company

  end
end