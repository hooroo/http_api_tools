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

class Employer

  include Hat::Model::Attributes

  attribute :id
  attribute :name
  attribute :people

  def person_ids
    people.map(&:id)
  end

end

class Skill

  include Hat::Model::Attributes

  attribute :id
  attribute :name
  attribute :person

  def person_id
    person.try(:id)
  end

end

