require 'hat/json_serializer'

class PersonSerializer

  include Hat::JsonSerializer

  attributes :id, :first_name, :last_name, :full_name, :dob, :email
  has_one :employer
  has_many :skills

  def full_name
    "#{serializable.first_name} #{serializable.last_name}"
  end

end

class EmployerSerializer

  include Hat::JsonSerializer

  attributes :id, :name
  has_many :people

end


class SkillSerializer

  include Hat::JsonSerializer

  attributes :id, :name, :description
  has_one :person

end