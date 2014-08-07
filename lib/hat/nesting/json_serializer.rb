require "active_support/core_ext/class/attribute"
require "active_support/json"
require 'active_support/core_ext/string/inflections'
require_relative '../base_json_serializer'

module Hat
  module Nesting
    module JsonSerializer

      include Hat::BaseJsonSerializer

    end
  end
end
