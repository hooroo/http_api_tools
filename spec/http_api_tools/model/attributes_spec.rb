# encoding: utf-8

require 'spec_helper'
require 'http_api_tools/model/attributes'

module HttpApiTools
  module Model

    describe Attributes do

      let(:test_model_class) do
        Class.new do
          include Attributes
          attribute :name
          attribute :dob, type: :date_time
          attribute :tags, default: []
          attribute :qualifications, default: { thing: 1 }
          attribute :source, default: 'internal'
          attribute :active
          belongs_to :parent
          has_many :children
        end
      end

      describe "attribute definition" do

        it "initializes attributes from constructor with coercions" do
          test_model = test_model_class.new(name: "Moonunit", tags: ["Musician", "Guitarist"])
          expect(test_model.name).to eq "Moonunit"
          expect(test_model.tags).to eq ["Musician", "Guitarist"]
        end

        it "transforms date value when date_time type is defined" do
          date_time_string = "2013-01-01T12:00:00.000Z"
          test_model = test_model_class.new(dob: date_time_string)
          expect(test_model.dob).to eq DateTime.parse(date_time_string)
        end

        it "sets default array if provided" do
          expect(test_model_class.new.tags).to eq []
        end

        it "sets default hash if provided" do
          expect(test_model_class.new.qualifications).to eq(thing: 1)
        end

        it "sets default primitive if provided" do
          expect(test_model_class.new.source).to eq 'internal'
        end

        it "multiple objects with default array don't share the same default reference" do
          a = test_model_class.new.tags
          b = test_model_class.new.tags
          expect(a).to_not be b
        end

        it "allows setting of values defined by attribute" do
          test_model = test_model_class.new
          test_model.name = 'New Name'
          expect(test_model.name).to eql 'New Name'
        end

        it "prevents default values not catered to default_for" do
          test_model_with_invalid_default = Class.new do
            include Attributes
            attribute :created_at, default: DateTime.now
          end
          expect{ test_model_with_invalid_default.new }.to raise_error

        end

        it 'sets a false value as false' do
           test_model = test_model_class.new(active: false)
           expect(test_model.active).to eq false
        end

        context "when given read_only as an option" do

          let(:test_model_with_read_only_attribute_class) do
            Class.new do
              include Attributes
              attribute :created_at, read_only: true
              attribute :some_cool_value
            end
          end


          let(:test_model) { test_model_with_read_only_attribute_class.new }

          context "when setting the read-only variable" do
            describe "initialize" do
              it "sets the read only value" do
                now = Time.now
                test_object = test_model_with_read_only_attribute_class.new(created_at: now)
                expect(test_object.created_at).to eq now
              end

            end

            it "only allows reading of http_api_tools attribute" do
              expect{ test_model.created_at = Time.now }.to raise_error(NoMethodError)
              expect(test_model.created_at).to be_nil
            end
          end

          context "when setting the non read-only variable" do
            it "allows reading and writing" do
              value = 'value'
              test_model.some_cool_value = value
              expect(test_model.some_cool_value).to eql value
            end
          end

        end
      end

      describe 'belongs_to' do

        let(:test_model) { test_model_class.new }
        let(:parent) { OpenStruct.new(id: 1) }

        it 'creates accessor for attribute name' do
          test_model.parent = parent
          expect(test_model.parent).to eq parent
        end

        it 'creates accessor for attribute_id' do
          test_model.parent_id = 1
          expect(test_model.parent_id).to eq 1
        end

        it 'updates the id attribute when the belongs_to attribute is updated' do
          test_model.parent = parent
          expect(test_model.parent_id).to eq 1
        end

      end

      describe 'has_many' do

        let(:test_model) { test_model_class.new }
        let(:child) { OpenStruct.new(id: 1) }

        it 'creates accessor for attribute name' do
          test_model.children = [child]
          expect(test_model.children).to eq [child]
        end

        it 'creates accessor for attributes_id' do
          test_model.child_ids = [1]
          expect(test_model.child_ids).to eq [1]
        end

        it 'updates the ids attribute when the has_many attribute is updated' do
          test_model.children = [OpenStruct.new(id: 3), OpenStruct.new(id: 4)]
          expect(test_model.child_ids).to eq [3, 4]
        end

      end

      describe "#errors" do
        it "adds accessors for errors" do
          test_model = test_model_class.new(errors: 'errors')
          expect(test_model.errors).to eql "errors"
        end
      end

    end
  end
end