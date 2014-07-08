# encoding: utf-8

require 'spec_helper'
require 'hat/model/has_many_array'

module Hat
  module Model
    describe HasManyArray do

      let(:has_many_attr_name) { 'things' }
      let(:owner) { double('owner', has_many_changed: nil) }
      let(:array) { HasManyArray.new([1], owner, has_many_attr_name) }

      describe "observing mutation" do

        before do
          owner.should_receive(:has_many_changed).with(array, has_many_attr_name)
        end

        it "notifies on <<" do
          array << 2
        end

        it "notifies on push" do
          array.push(2)
        end

        it "notifies on delete" do
          array.delete(1)
        end

        it "notifies on delete_at" do
          array.delete_at(0)
        end

        it "notifies on clear" do
          array.clear
        end

        it "notifies on shift" do
          array.shift
        end

      end

    end
  end
end