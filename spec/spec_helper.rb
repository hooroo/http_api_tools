# encoding: utf-8

begin
  require 'ruby-prof'
  RUBY_PROF = true
rescue LoadError
  RUBY_PROF = false
end

RSpec.configure do
  def ruby_profile(name, &block)
    RubyProf.start

    result = block.call

    profile_result = RubyProf.stop
    printer = RubyProf::CallStackPrinter.new(profile_result)
    report_file = File.open(File.expand_path("../../reports/profile_report_#{name}.html", __FILE__), "w")
    printer.print(report_file)

    result
  end

  def profile(name, &block)
    start = Time.now

    result = if RUBY_PROF
      ruby_profile(name, &block)
    else
      block.call
    end

    puts "#{name}: #{(Time.now - start) * 1000} ms"

    result
  end

end

require 'http_api_tools/support/spec_models_for_serializing'
require 'http_api_tools/support/spec_models_for_deserializing'
require 'http_api_tools/support/spec_sideloading_serializers'
require 'http_api_tools/support/spec_nesting_serializers'
require 'active_support/core_ext/hash/indifferent_access'
require 'rubygems'
require 'pry'
