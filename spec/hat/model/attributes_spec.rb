# encoding: utf-8

require 'spec_helper'
require 'hat/model/attributes'

module Hat
  module Model

    describe Attributes do

      let(:test_model_class) do
        Class.new do
          include Attributes
          attribute :name
          attribute :dob, type: :date_time
          attribute :tags, default: []
          attribute :qualifications, default: {thing: 1}
          attribute :source, default: 'internal'
        end
      end

      describe "attribute definition" do

        it "initializes attributes from constructor with coercions" do
          test_model = test_model_class.new(name: "Moonunit", tags: ["Musician", "Guitarist"])
          expect(test_model.name).to eq "Moonunit"
          expect(test_model.tags).to eq ["Musician", "Guitarist"]
        end

        it "coerces values when type is defined" do
          date_time_string = "2013-01-01T12:00:00.000Z"
          test_model = test_model_class.new(dob: date_time_string)
          expect(test_model.dob).to eq DateTime.parse(date_time_string)
        end

        it "sets default array if provided" do
          expect(test_model_class.new.tags).to eq []
        end

        it "sets default hash if provided" do
          expect(test_model_class.new.qualifications).to eq({thing: 1})
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

        context "when given read_only as an option" do

          let(:test_model_with_read_only_attribute_class) do
            Class.new do
              include Attributes
              attribute :created_at, read_only: true
              attribute :some_cool_value
            end
          end


          let(:test_model) { test_model_with_read_only_attribute_class.new }

          context "the read-only variable" do
            context "the initializer" do
              context "when set_read_only not provided" do
                it "when passing a read-only variable into the initializer should raise a no method error" do
                  expect{test_model_with_read_only_attribute_class.new(created_at: Time.now)}.to raise_error(NoMethodError)
                end
              end

              context "when set_read_only set to true" do
                it "when passing a read-only variable into the initializer should raise a no method error" do
                  value = Time.now
                  model = test_model_with_read_only_attribute_class.new(created_at: value, set_read_only: true)
                  expect(model.created_at).to eq value
                end
              end
            end

            it "only allows reading of that attribute" do
              expect{test_model.created_at = Time.now}.to raise_error(NoMethodError)
              expect(test_model.created_at).to be_nil
            end
          end

          context "the non read-only variable" do
            it "allows reading and writing" do
              value = Time.now
              test_model.some_cool_value = value
              expect(test_model.some_cool_value).to eql value
            end
          end

        end
      end

      describe "#errors" do
        it "adds accessors for errors" do
          test_model = test_model_class.new(errors: 'errors')
          expect(test_model.errors).to eql "errors"
        end
      end

      describe "#as_json" do
        let(:test_model_class) do
          Class.new do
            include Attributes
            attribute :created_at, read_only: true
            attribute :some_cool_value
          end
        end

        context "when not provided options" do
          it "includes all attributes in a hash" do
            expect(test_model_class.new(some_cool_value: 'yeah cool!').as_json).to eq(
              {
                created_at: nil,
                some_cool_value: 'yeah cool!',
                errors: {}
              }
            )
          end
        end

        context "when provided the exclude_read_only option" do
          it "exclude all read only attributes in a hash" do
            expect(test_model_class.new(some_cool_value: 'yeah cool!').as_json(exclude_read_only: true)).to eq(
              {
                some_cool_value: 'yeah cool!',
                errors: {}
              }
            )
          end

          it 'does not remove the read_only attributes from the original attributes hash' do
            test_model = test_model_class.new
            test_model.as_json(exclude_read_only: true)
            expect(test_model.attributes).to include(:created_at)
          end
        end
      end

    end
  end
end