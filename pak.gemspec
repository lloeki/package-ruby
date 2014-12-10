Gem::Specification.new do |s|
  s.name = 'pak'
  s.version = '1.0.0'
  s.licenses = ['MIT']
  s.summary = 'Packaged namespacing for Ruby'
  s.description = 'Implicit namespacing and package definition, '\
                  'inspired by Python, Go, CommonJS.'
  s.authors = ['Loic Nageleisen']
  s.email = 'loic.nageleisen@gmail.com'
  s.files = Dir['lib/*']

  s.add_development_dependency 'rake', '~> 10.3'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'yard', '~> 0.8.7'
  s.add_development_dependency 'binding_of_caller'

  s.add_development_dependency 'pry'
end
