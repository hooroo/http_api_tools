require "bundler/gem_tasks"
require 'rspec/core/rake_task'

task :default => :spec
RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = "--tag ~perf"
end

RSpec::Core::RakeTask.new(:perf) do |t|
    t.rspec_opts = "--tag perf"
end
