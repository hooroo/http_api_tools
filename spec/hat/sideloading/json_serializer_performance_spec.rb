require 'spec_helper'
require 'ruby-prof'

module Hat
  module Sideloading

    # Rudimentary performance profiler - uncomment to run on demand for now


    # describe JsonSerializer do

    #   let!(:companies) do
    #     start = Time.now
    #     companies = (1..100).map do |company_id|
    #       company = Company.new(id: company_id, name: "Company #{rand(company_id)}")
    #       people = (1..100).map do |person_id|
    #         person = Person.new(id: person_id, first_name: "First #{rand(person_id)}", last_name: "Last #{rand(person_id)}", dob: Date.today, email: 'user@example.com', employer: company)
    #         skills = (1..20).map do |skill_id|
    #           skill = Skill.new(id: skill_id, name: "Skill #{rand(skill_id)}", description: "abc123" * 500, person: person)
    #         end
    #         person.skills = skills
    #         person
    #       end
    #       company.employees = people
    #       company
    #     end
    #     puts "BUILD MODEL: #{(Time.now - start) * 1000} ms"
    #     companies
    #   end

    #   it "serializes" do
    #     RubyProf.start
    #     serialized = CompanySerializer.new(companies).includes(:employer, {employees: [:skills]}).as_json
    #     result = RubyProf.stop
    #     printer = RubyProf::CallStackPrinter.new(result)
    #     report_file = File.open(File.expand_path("../../../reports/profile_report.html", __FILE__), "w")
    #     printer.print(report_file)

    #     start = Time.now
    #     serialized = CompanySerializer.new(companies).includes(:employer, {employees: [:skills]}).as_json
    #     puts "SERIALIZE: #{(Time.now - start) * 1000} ms"

    #     start = Time.now
    #     JSON.fast_generate(serialized)
    #     puts "TO_JSON: #{(Time.now - start) * 1000} ms"

    #   end

    # end
  end
end