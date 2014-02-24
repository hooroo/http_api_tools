# encoding: utf-8

require 'spec_helper'
require 'hat/json_serializer'

module Hat

  describe JsonSerializer do

    let(:company) { Company.new(id: 1, name: 'Hooroo') }
    let(:person) { Person.new(id: 2, first_name: 'Rob', last_name: 'Monie') }
    let(:skill) { Skill.new(id: 3, name: "JSON Serialization") }
    let(:skill2) { Skill.new(id: 4, name: "JSON Serialization 2") }

    before do
      company.employees = [person]
      person.employer = company
      person.skills = [skill, skill2]
      skill.person = person
      skill2.person = person
    end

    describe "serialization of data" do
      context "with a single top-level serializable object that has relationship names different to model class" do

        context "without any includes" do

          let(:serialized) { PersonSerializer.new(person).as_json.with_indifferent_access }
          let(:serialized_person) { serialized[:people].first }

          it "serializes basic attributes" do
            expect(serialized_person[:id]).to eql person.id
            expect(serialized_person[:first_name]).to eql person.first_name
            expect(serialized_person[:last_name]).to eql person.last_name
          end

          it 'expect basic attributes with no value' do
            expect(serialized_person.has_key?(:dob)).to be_true
          end

          it "serializes attributes defined as methods on the serializer" do
            expect(serialized_person[:full_name]).to eql "#{person.first_name} #{person.last_name}"
          end

          it "serializes relationships as ids" do
            expect(serialized_person[:links][:employer]).to eql person.employer.id
            expect(serialized_person[:links][:skills]).to eql person.skills.map(&:id)
          end

          it "doesn't serialize any relationships" do
            expect(serialized[:linked][:companies]).to be_nil
            expect(serialized[:linked][:skills]).to be_nil
          end

        end

        context "with relations specified as includes" do

          let(:serialized) do
            PersonSerializer.new(person).includes(:employer, {skills: [:person]}).as_json.with_indifferent_access
          end

          let(:serialized_person) { serialized[:people].first }

          it "serializes relationships as ids" do
            expect(serialized_person[:links][:employer]).to eql person.employer.id
            expect(serialized_person[:links][:skills]).to eql person.skills.map(&:id)
          end

          it "sideloads has_one relationships" do
            expect(serialized[:linked][:companies].first[:name]).to eql person.employer.name
          end

          it "sideloads has_many relationships" do
            expect(serialized[:linked][:skills].first[:name]).to eql person.skills.first.name
          end

        end

      end

      context "with an array as the serializable object" do

        let(:relation) do
          [person, second_person]
        end

        let(:second_person) { Person.new(id: 5, first_name: 'Stu', last_name: 'Liston') }
        let(:serialized) { JSON.parse(PersonSerializer.new(relation).to_json).with_indifferent_access }

        before do
          company.employees = [person, second_person]
          person.employer = company
          second_person.employer = company
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

      describe "meta data" do

        let(:serializer) { PersonSerializer.new(person) }

        it "adds root key" do
          expect(serializer.as_json[:meta][:root_key]).to eql 'people'
        end

        it "adds type" do
          expect(serializer.as_json[:meta][:type]).to eql 'person'
        end

        it "allows meta data to be added" do
          serializer.meta(offset: 0, limit: 10)
          expect(serializer.as_json[:meta][:offset]).to eql 0
          expect(serializer.as_json[:meta][:limit]).to eql 10
        end

      end

      describe "limiting sideloadable data" do

        class LimitedSideloadingPersonSerializer < PersonSerializer
          includable :employer, :skills
        end

        let(:unlimited_serialized) { PersonSerializer.new(person).includes(:employer, {skills: [:person]}).as_json.with_indifferent_access }

        let(:limited_serialized) do
          LimitedSideloadingPersonSerializer.new(person).includes(:employer, {skills: [:person]}).as_json.with_indifferent_access
        end

        it "does not limit sideloading if not limited in serializer" do
          expect(unlimited_serialized[:linked][:people].first[:id]).to eq person.id
        end

        it "allows sideloading of includable relations" do
          expect(limited_serialized[:linked][:skills].first[:name]).to eql person.skills.first.name
        end

        it "prevents sideloading of non-includable relations" do
          expect(limited_serialized[:linked][:people]).to be_nil
        end

        it "includes what is includables in meta" do
          expect(limited_serialized[:meta][:includable]).to eq 'employer,skills'
        end

        it "includes what was included in meta" do
          expect(limited_serialized[:meta][:included]).to eq 'employer,skills'
          expect(unlimited_serialized[:meta][:included]).to eq 'employer,skills,skills.person'
        end

      end
    end
  end
end
