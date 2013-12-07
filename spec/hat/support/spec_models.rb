require 'hat/model'


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

  def skill_ids
    skills.map(&:id)
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

  def employee_ids
    employees.map(&:id)
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

end

class Address

  attr_accessor :id, :street_address

  def initialize(attrs)
    @id = attrs[:id]
    @street_address = attrs[:street_address]
  end

end

