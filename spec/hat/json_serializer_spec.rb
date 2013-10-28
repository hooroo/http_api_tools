require 'spec_helper'
require 'hat/json_serializer'

module Hat
  describe JsonSerializer do

    let(:employer) { Employer.new(id: 1, name: 'Hooroo') }
    let(:person) { Person.new(id: 2, first_name: 'Rob', last_name: 'Monie') }
    let(:skill) { Skill.new(id: 3, name: "JSON Serialization") }

    before do
      employer.people = [person]
      person.employer = employer
      person.skills = [skill]
      skill.person = person
    end

    context "with a single top-level serializable object" do

      context "without any includes" do

        let(:serialized) { PersonSerializer.new(person).as_json.with_indifferent_access }

        it "serializes basic attributes" do
          expect(serialized[:person][:id]).to eql person.id
          expect(serialized[:person][:first_name]).to eql person.first_name
          expect(serialized[:person][:last_name]).to eql person.last_name
          expect(serialized[:person][:id]).to eql person.id
        end

        it "serializes attributes defined as methods on the serializer" do
          expect(serialized[:person][:full_name]).to eql "#{person.first_name} #{person.last_name}"
        end

        it "serializes relationships as ids" do
          expect(serialized[:person][:employer_id]).to eql person.employer.id
          expect(serialized[:person][:skill_ids]).to eql person.skills.map(&:id)
        end

        it "doesn't serialize any relationships" do
          expect(serialized[:employers]).to be_nil
          expect(serialized[:skills]).to be_nil
        end

      end

      context "with relations specified as includes" do

        let(:serialized) do
          PersonSerializer.new(person).includes(:employer, :skills).as_json.with_indifferent_access
        end

        it "serializes relationships as ids" do
          expect(serialized[:person][:employer_id]).to eql person.employer.id
          expect(serialized[:person][:skill_ids]).to eql person.skills.map(&:id)
        end

        it "sideloads has_one relationships" do
          expect(serialized[:employers].first[:name]).to eql person.employer.name
        end

        it "sideloads has_many relationships" do
          expect(serialized[:skills].first[:name]).to eql person.skills.first.name
        end

      end


    end

    context "with an active record relation as the serializable object" do

      let(:relation) do
        relation = [person, second_person]
        # active record relation responds to klass. There is def a better way to determine this
        def relation.klass
          Person
        end
        relation
      end

      let(:second_person) { Person.new(id: 5, first_name: 'Stu', last_name: 'Liston') }
      let(:serialized) { JSON.parse(PersonSerializer.new(relation).to_json).with_indifferent_access }

      before do
        employer.people = [person, second_person]
        person.employer = employer
        second_person.employer = employer
        person.skills = [skill]
        second_person.skills = []
        skill.person = person
      end

      it "serializes basic attributes of all items in the array" do
        expect(serialized[:people][0][:id]).to eql person.id
        expect(serialized[:people][0][:first_name]).to eql person.first_name
        expect(serialized[:people][0][:last_name]).to eql person.last_name
        expect(serialized[:people][0][:id]).to eql person.id

        expect(serialized[:people][1][:id]).to eql second_person.id
        expect(serialized[:people][1][:first_name]).to eql second_person.first_name
        expect(serialized[:people][1][:last_name]).to eql second_person.last_name
        expect(serialized[:people][1][:id]).to eql second_person.id
      end

    end

  end

end

class PersonSerializer

  include Hat::JsonSerializer

  attributes :id, :first_name, :last_name, :full_name
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

  attributes :id, :name
  has_one :person

end

class Person

  attr_accessor :id, :first_name, :last_name, :employer, :skills

  def initialize(attrs)
    @id = attrs[:id]
    @first_name = attrs[:first_name]
    @last_name = attrs[:last_name]
    @first_name = attrs[:first_name]
    @employer = attrs[:employer]
    @skils = attrs[:skills]
  end

  def employer_id
    employer.id
  end

  def skill_ids
    skills.map(&:id)
  end

end

class Employer

  attr_accessor :id, :name, :people

  def initialize(attrs)
    @id = attrs[:id]
    @name = attrs[:name]
    @people = attrs[:people]
  end

  def person_ids
    people.map(&:id)
  end

end

class Skill

  attr_accessor :id, :name, :person

  def initialize(attrs)
    @id = attrs[:id]
    @name = attrs[:name]
    @person = attrs[:person]
  end

end

