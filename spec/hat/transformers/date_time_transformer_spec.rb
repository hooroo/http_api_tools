require 'spec_helper'
require 'hat/transformers/date_time_transformer'


module Hat
  module Transformers

    describe DateTimeTransformer do

      let(:transformer) { DateTimeTransformer }

      describe '.from_raw_value' do

        it "transforms a date_time string" do
          date_time_string = "2013-01-01T12:00:00.000Z"
          expect(transformer.from_raw(date_time_string)).to eq DateTime.parse(date_time_string)
        end

        it "passes through date_time instances" do
          now = DateTime.now
          expect(transformer.from_raw(now)).to eql now
        end

        it "passes through nil" do
          expect(transformer.from_raw(nil)).to eql nil
        end

        it "raises transform error on untransformable types" do
          lambda { transformer.from_raw(11.11) }.should raise_error TransformError
        end
      end
    end
  end
end