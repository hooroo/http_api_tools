require 'spec_helper'

module HttpApiTools
  module Nesting

     #Rudimentary performance profiler - uncomment to run on demand for now
     describe JsonSerializer do

       def create_models
         companies = (1..100).map do |company_id|
           company = Company.new(id: company_id, name: "Company #{rand(company_id)}")
           people = (1..100).map do |person_id|
             person = Person.new(id: person_id, first_name: "First #{rand(person_id)}", last_name: "Last #{rand(person_id)}", dob: Date.today, email: 'user@example.com', employer: company)
             skills = (1..20).map do |skill_id|
               skill = Skill.new(id: skill_id, name: "Skill #{rand(skill_id)}", description: "abc123", person: person)
             end
             person.skills = skills
             person
           end
           company.employees = people
           company
         end
       end

       let!(:companies) do
         profile('nested-models') do
           create_models
         end
       end

       it 'serializes', perf: true do

         serialized = profile('nested-serializes') do
           CompanySerializer.new(companies).includes(:employer, {employees: [:skills]}).as_json
         end

         profile('nested-json') do
           JSON.fast_generate(serialized)
         end
       end

     end
  end
end
