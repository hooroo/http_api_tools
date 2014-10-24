require 'http_api_tools/sideloading/json_deserializer_mapping'

class PersonDeserializerMapping

  include HttpApiTools::Sideloading::JsonDeserializerMapping

  map :employer, Company

end