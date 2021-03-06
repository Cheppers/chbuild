# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/contur/version'

Gem::Specification.new do |spec|
  spec.name          = 'contur'
  spec.version       = Contur::VERSION
  spec.author        = 'Cheppers Ltd.'
  spec.email         = 'info@cheppers.com'
  spec.summary       = 'Contur - Local Web Development Tool'
  spec.homepage      = 'https://github.com/Cheppers/contur'
  spec.license       = 'MIT'
  spec.description   = IO.read('README.md').match(/# Contur\n^(?<desc>.*)$/)[:desc]

  spec.required_ruby_version = '>= 2.6.0'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  spec.bindir        = 'bin'
  spec.executables   = ['contur']
  spec.require_paths = ['lib']

  spec.add_dependency 'colorize', '~> 0.8'
  spec.add_dependency 'docker-api', '~> 1.31', '>= 1.31'
  spec.add_dependency 'excon', '~> 0.71.0'
  spec.add_dependency 'thor', '~> 0.19'
  spec.add_dependency 'thor-zsh_completion', '~> 0.1.1'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'cucumber', '~> 2.4'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'rake', '~> 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.51'
  spec.add_development_dependency 'simplecov', '~> 0.12'
  spec.add_development_dependency 'simplecov-console', '~> 0.3'
end
