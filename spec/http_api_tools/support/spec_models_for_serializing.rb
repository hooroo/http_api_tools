# encoding: utf-8

require 'http_api_tools/model'
require 'ostruct'


class Person

  include HttpApiTools::Model::Attributes

  attribute :id
  attribute :first_name
  attribute :last_name
  attribute :dob
  attribute :email, exclude_when: :exclude_email?
  attribute :tax_file_number
  attribute :something_personal
  attribute :something_public
  belongs_to :employer
  belongs_to :previous_employer
  has_many :skills
  has_many :hidden_talents

  #Act like active record for reflectively interogating type info
  def self.reflections
    {
      employer: OpenStruct.new(class_name: 'Company'),
      previous_employer: OpenStruct.new(class_name: 'Company'),
      skills: OpenStruct.new(class_name: 'Skill'),
      hidden_talents: OpenStruct.new(class_name: 'Skill')
    }
  end

end

class Company

  include HttpApiTools::Model::Attributes

  attribute :id
  attribute :name
  attribute :phone
  attribute :brand, read_only: true
  has_many :employees
  has_many :suppliers
  belongs_to :parent_company
  belongs_to :address


  #Act like active record for reflectively interogating type info
  def self.reflections
    {
      employees: OpenStruct.new(class_name: 'Person'),
      suppliers: OpenStruct.new(class_name: 'Company'),
      parent_company: OpenStruct.new(class_name: 'Company'),
      address: OpenStruct.new(class_name: 'Address')
    }
  end

end

class Skill

  include HttpApiTools::Model::Attributes

  attribute :id
  attribute :name
  attribute :description
  belongs_to :person

  #Act like active record for reflectively interogating type info
  def self.reflections
    {
      person: OpenStruct.new(class_name: 'Person')
    }
  end

end

class Address

  include HttpApiTools::Model::Attributes

  attribute :id
  attribute :street_address

end
