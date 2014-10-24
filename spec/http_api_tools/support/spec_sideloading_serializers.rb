require 'http_api_tools/sideloading/json_serializer'

module HttpApiTools
  module Sideloading
    class PersonSerializer

      include HttpApiTools::Sideloading::JsonSerializer

      serializes Person
      attributes :id, :first_name, :last_name, :full_name, :dob, :email
      has_one :employer
      has_many :skills

      def full_name
        "#{serializable.first_name} #{serializable.last_name}"
      end

    end

    class CompanySerializer

      include HttpApiTools::Sideloading::JsonSerializer

      serializes Company
      attributes :id, :name
      has_many :employees

    end


    class SkillSerializer

      include HttpApiTools::Sideloading::JsonSerializer

      serializes Skill
      attributes :id, :name, :description
      has_one :person

    end
  end
end