require 'spec_helper'
require 'hat/model/type_coercions'

module Model

  describe TypeCoercions do

    class TypeCoercer
      include TypeCoercions
    end

    let(:type_coercer) { TypeCoercer.new }


    describe "date_time" do

      it "coerces a date_time string" do
        date_time_string = "2013-01-01T12:00:00.000Z"
        expect(type_coercer.to_date_time(date_time_string)).to eq DateTime.parse(date_time_string)
      end

      it "passes through date_time instances" do
        now = DateTime.now
        expect(type_coercer.to_date_time(now)).to eql now
      end

      it "passes through nil" do
        expect(type_coercer.to_date_time(nil)).to eql nil
      end

      it "raises coercion error on uncoercible types" do
        lambda { type_coercer.to_date_time(11.11) }.should raise_error Model::CoercionError
      end

    end
  end
end