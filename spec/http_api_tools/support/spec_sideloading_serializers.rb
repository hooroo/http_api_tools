require 'http_api_tools/sideloading/json_serializer'

module HttpApiTools
  module Sideloading
    class PersonSerializer

      include HttpApiTools::Sideloading::JsonSerializer

      serializes Person
      attribute :id
      attribute :first_name
      attribute :last_name
      attribute :full_name
      attribute :dob

      attribute :email, exclude_when: :exclude_email?
      attribute :tax_file_number, exclude_when: :exclude_tax_file_number?
      attribute :something_personal, exclude_when: -> (serializable) { true }
      attribute :something_public, exclude_when: -> (serializable) { false }

      has_one :employer
      has_one :previous_employer, exclude_when: -> (serializable) { true }
      has_many :skills
      has_many :hidden_talents, exclude_when: -> (serializable) { true }


      def full_name
        "#{serializable.first_name} #{serializable.last_name}"
      end

      def exclude_tax_file_number?
        true
      end

      def exclude_email?
        false
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

    class AlternatePersonSerializer
      include HttpApiTools::Sideloading::JsonSerializer

      serializes(Person, group: :alternate)
      attributes :id, :first_name, :last_name
      has_one :employer
      has_many :skills

    end

    class AlternateCompanySerializer

      include HttpApiTools::Sideloading::JsonSerializer

      serializes(Company, group: :alternate)
      attributes :id, :name
      has_many :employees

    end


    class AlternateSkillSerializer

      include HttpApiTools::Sideloading::JsonSerializer

      serializes(Skill, group: :alternate)
      attributes :id, :name

    end
  end
end