require "http_api_tools/version"
require 'http_api_tools/nesting/json_serializer'
require 'http_api_tools/sideloading/json_serializer'
require 'http_api_tools/sideloading/json_deserializer'
require 'http_api_tools/model'
require 'http_api_tools/relation_includes'

module HttpApiTools

  #Make sure all serializers have been loaded so that relationships can be properly resolved
  SerializerLoader.load_serializers
end
