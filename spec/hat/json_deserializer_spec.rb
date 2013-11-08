require 'spec_helper'
require 'hat/json_deserializer'

module Hat

  describe JsonDeserializer do

    let(:json) do
      {
        'meta' => {
          'type' => 'employer',
          'root_key' => 'employers'
        },
        'employers' => [{
          'id' => 1,
          'name' => "Hooroo",
          'links' => {
            'employees' => [10, 11, 12],
            'address' => 20,
            'suppliers' => [30],
            'parent_company' => 40
          }
        }],
        'linked' => {
          'employees' => [
            {'id' => 10, 'name' => 'Rob', 'links' => { 'employer' => 1 } },
            {'id' => 11, 'name' => 'Stu', 'links' => { 'employer' => 1 } },
            {'id' => 12, 'name' => 'Dan', 'links' => { 'employer' => 1 } },
          ],
          'addresses' => [
            {'id' => 20, 'street_address' => "1 Burke Street"}
          ]
        }

      }

    end

    let(:employer)  { JsonDeserializer.new(json).deserialize.first }

    describe "basic deserialization" do

      it "creates model from the root object" do
        expect(employer.id).to eq json['employers'][0]['id']
        expect(employer.name).to eq json['employers'][0]['name']
      end

      it "includes sideloaded has many relationships" do
        expect(employer.employees.size).to eql 3
        expect(employer.employees.first.name).to eq json['linked']['employees'].first['name']
      end

      it "includes sideloaded has_one relationships" do
        expect(employer.address.street_address).to eq json['linked']['addresses'].first['street_address']
      end

      it "includes circular relationships" do
        expect(employer.employees.first.employer.name).to eq json['employers'][0]['name']
      end

      it "has_many relationships without sideloaded data are set to an empty array" do
        expect(employer.suppliers).to eql []
      end

      it "has_one relationships without sideloaded data are set to nil" do
        expect(employer.parent_company).to eql nil
      end

    end
  end
end

class Employer

  attr_accessor :id, :name, :address, :employees, :suppliers, :parent_company

  def initialize(attrs)
    @id = attrs[:id]
    @name = attrs[:name]
    @address = attrs[:address]
    @employees = attrs[:employees]
    @suppliers = attrs[:suppliers]
    @parent_company = attrs[:parent_company]
  end

end


class Employee

  attr_accessor :id, :name, :employer

  def initialize(attrs)
    @id = attrs[:id]
    @name = attrs[:name]
    @employer = attrs[:employer]
  end

end

class Address

  attr_accessor :id, :street_address

  def initialize(attrs)
    @id = attrs[:id]
    @street_address = attrs[:street_address]
  end

end