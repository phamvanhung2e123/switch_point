require "bundler/gem_tasks"

task :default => :spec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc 'Run benchmark'
task :benchmark do
  sh 'bundle', 'exec', 'ruby', 'benchmark/proxy.rb'
end
