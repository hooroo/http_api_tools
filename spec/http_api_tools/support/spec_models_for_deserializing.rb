# encoding: utf-8

require 'http_api_tools/model'
require 'ostruct'

class Coffee
  include HttpApiTools::Model::Attributes

  attribute :id
  attribute :name
end

module ForDeserializing
  class Person

    include HttpApiTools::Model::Attributes

    attribute :id
    attribute :first_name
    attribute :last_name
    attribute :dob
    attribute :email
    belongs_to :employer
    has_many :skills

  end

  class Company

    include HttpApiTools::Model::Attributes

    attribute :id
    attribute :name
    attribute :brand, read_only: true
    has_many :employees
    has_many :suppliers
    belongs_to :parent_company
    belongs_to :address

  end

  class Skill

    include HttpApiTools::Model::Attributes

    attribute :id
    attribute :name
    attribute :description
    belongs_to :person

  end

  class Address

    include HttpApiTools::Model::Attributes

    attribute :id
    attribute :street_address

  end
end
