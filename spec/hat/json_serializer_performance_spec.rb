require 'spec_helper'
require 'ruby-prof'

module Hat

  describe JsonSerializer do

    let!(:employers) do
      start = Time.now
      employers = (1..100).map do |employer_id|
        employer = Employer.new(id: employer_id, name: "Employer #{rand(employer_id)}")
        people = (1..100).map do |person_id|
          person = Person.new(id: person_id, first_name: "First #{rand(person_id)}", last_name: "Last #{rand(person_id)}", employer: employer)
          skills = (1..20).map do |skill_id|
            skill = Skill.new(id: skill_id, name: "Skill #{rand(skill_id)}", person: person)
          end
          person.skills = skills
          person
        end
        employer.people = people
        employer
      end
      puts "BUILD MODEL: #{(Time.now - start) * 1000} ms"
      employers
    end

    it "serializes" do
      RubyProf.start
      serialized = EmployerSerializer.new(employers).includes(:employer, {people: [:skills]}).as_json
      result = RubyProf.stop
      printer = RubyProf::CallStackPrinter.new(result)
      report_file = File.open(File.expand_path("../../../reports/profile_report.html", __FILE__), "w")
      printer.print(report_file)

      start = Time.now
      serialized = EmployerSerializer.new(employers).includes(:employer, {people: [:skills]}).as_json
      puts "SERIALIZE: #{(Time.now - start) * 1000} ms"

      start = Time.now
      JSON.fast_generate(serialized)
      puts "TO_JSON: #{(Time.now - start) * 1000} ms"

    end

  end
end