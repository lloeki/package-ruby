require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']
  t.options = %w(- README.md LICENSE CONTRIBUTING)
end

require 'rspec/core'
require 'rspec/core/rake_task'
desc 'Run all specs in spec directory (excluding plugin specs)'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new

desc 'Run RSpec with code coverage'
task :coverage do
  ENV['COVERAGE'] = 'yes'
  Rake::Task['spec'].execute
end

task default: :spec
