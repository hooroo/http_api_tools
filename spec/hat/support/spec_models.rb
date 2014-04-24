# encoding: utf-8

require 'hat/model'
require 'ostruct'


class Person

  include Hat::Model::Attributes

  attribute :id
  attribute :first_name
  attribute :last_name
  attribute :dob
  attribute :email
  attribute :employer
  attribute :skills

  def employer_id
    employer.try(:id)
  end

  # def skill_ids
  #   skills.map(&:id)
  # end

  #Act like active record for reflectively interogating type info
  def self.reflections
    {
      employer: OpenStruct.new(class_name: 'Company'),
      skills:   OpenStruct.new(class_name: 'Skill')
    }
  end

end

class Company

  include Hat::Model::Attributes

  attribute :id
  attribute :name
  attribute :employees
  attribute :suppliers
  attribute :parent_company
  attribute :address
  attribute :brand, read_only: true

  # def employee_ids
  #   employees.map(&:id)
  # end

  #Act like active record for reflectively interogating type info
  def self.reflections
    {
      employees:      OpenStruct.new(class_name: 'Person'),
      suppliers:      OpenStruct.new(class_name: 'Company'),
      parent_company: OpenStruct.new(class_name: 'Company'),
      address:        OpenStruct.new(class_name: 'Address')
    }
  end

end

class Skill

  include Hat::Model::Attributes

  attribute :id
  attribute :name
  attribute :description
  attribute :person

  def person_id
    person.try(:id)
  end

  #Act like active record for reflectively interogating type info
  def self.reflections
    {
      person: OpenStruct.new(class_name: 'Person')
    }
  end

end

class Address

  attr_accessor :id, :street_address

  def initialize(attrs)
    @id = attrs[:id]
    @street_address = attrs[:street_address]
  end

end
