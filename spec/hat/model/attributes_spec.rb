require 'spec_helper'
require 'hat/model/attributes'

module Model

  describe Attributes do

    class TestModel
      include Attributes
      attribute :name
      attribute :dob, type: :date_time
      attribute :tags, default: []
    end

    describe "attribute definition" do

      it "initializes attributes from constructor with coercions" do
        test_model = TestModel.new(name: "Moonunit", tags: ["Musician", "Guitarist"])
        expect(test_model.name).to eq "Moonunit"
        expect(test_model.tags).to eq ["Musician", "Guitarist"]
      end

      it "coerces values when type is defined" do
        date_time_string = "2013-01-01T12:00:00.000Z"
        test_model = TestModel.new(dob: date_time_string)
        expect(test_model.dob).to eq DateTime.parse(date_time_string)
      end

      it "sets default if provided" do
        expect(TestModel.new.tags).to eq []
      end

      it "multiple objects with default array don't share the same default reference" do
        a = TestModel.new.tags
        b = TestModel.new.tags
        expect(a).to_not be b
      end

      it "allows setting of values defined by attribute" do
        test_model = TestModel.new
        test_model.name = 'New Name'
        expect(test_model.name).to eql 'New Name'
      end

      it "prevents default values not catered to default_for" do
        class TestModelWithInvalidDefault
          include Attributes
          attribute :created_at, default: DateTime.now
        end

        lambda { TestModelWithInvalidDefault.new }.should raise_error

      end
    end

    describe "errors" do
      it "adds accessors for errors" do
        test_model = TestModel.new(errors: 'errors')
        expect(test_model.errors).to eql "errors"
      end
    end

  end
end