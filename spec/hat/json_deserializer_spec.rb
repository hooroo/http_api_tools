# encoding: utf-8

require 'spec_helper'
require 'hat/json_deserializer'
require 'hat/support/company_deserializer_mapping'
require 'hat/support/person_deserializer_mapping'

module Hat

  describe JsonDeserializer do

    let(:json) do
      {
        'meta' => {
          'type' => 'company',
          'root_key' => 'companies'
        },
        'companies' => [{
          'id' => 1,
          'name' => "Hooroo",
          'brand' => "We are travellers or something",
          'links' => {
            'employees' => [10, 11, 12],
            'address' => 20,
            'suppliers' => [30],
            'parent_company' => 40
          }
        }],
        'linked' => {
          'people' => [
            {'id' => 10, 'first_name' => 'Rob', 'links' => { 'employer' => 1 } },
            {'id' => 11, 'first_name' => 'Stu', 'links' => { 'employer' => 1 } },
            {'id' => 12, 'first_name' => 'Dan', 'links' => { 'employer' => 1 } },
          ],
          'addresses' => [
            {'id' => 20, 'street_address' => "1 Burke Street"}
          ]
        }

      }

    end

    let(:company) do
      JsonDeserializer.new(json).deserialize.first
    end

    describe "basic deserialization" do

      it "creates model from the root object" do
        expect(company.id).to eq json['companies'][0]['id']
        expect(company.name).to eq json['companies'][0]['name']
      end

      it "can set read-only attributes" do
        expect(company.brand).to eq json['companies'][0]['brand']
      end

      it "includes sideloaded has many relationships" do
        expect(company.employees.size).to eql 3
        expect(company.employees.first.first_name).to eq json['linked']['people'].first['first_name']
      end

      it "includes sideloaded has_one relationships" do
        expect(company.address.street_address).to eq json['linked']['addresses'].first['street_address']
      end

      it "includes circular relationships" do
        expect(company.employees.first.employer.name).to eq json['companies'][0]['name']
      end

      it "has_many relationships without sideloaded data are set to an empty array" do
        expect(company.suppliers).to eql []
      end

      it "has_one relationships without sideloaded data are set to nil" do
        expect(company.parent_company).to eql nil
      end

    end
  end
end
