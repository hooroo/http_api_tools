require 'http_api_tools/nesting/json_serializer'

module HttpApiTools
  module Nesting
    class PersonSerializer

      include HttpApiTools::Nesting::JsonSerializer

      serializes Person
      attributes :id, :first_name, :last_name, :full_name, :dob, :email
      has_one :employer
      has_many :skills

      def full_name
        "#{serializable.first_name} #{serializable.last_name}"
      end

    end

    class CompanySerializer

      include HttpApiTools::Nesting::JsonSerializer

      serializes Company
      attributes :id, :name
      has_many :employees

    end


    class SkillSerializer

      include HttpApiTools::Nesting::JsonSerializer

      serializes Skill
      attributes :id, :name, :description
      has_one :person

    end
  end
end