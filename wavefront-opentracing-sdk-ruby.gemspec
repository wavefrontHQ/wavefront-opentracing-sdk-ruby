# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/wavefrontopentracing/version'

Gem::Specification.new do |spec|
  spec.name          = 'wavefront-opentracing-sdk'
  spec.version       = WavefrontOpentracing::VERSION
  spec.authors       = ['Gangadharaswamy']
  spec.email         = ['chitimba@wavefront.com']

  spec.summary       = 'Wavefront OpenTracing SDK for Ruby'
  spec.homepage      = 'https://github.com/wavefrontHQ/wavefront-opentracing-sdk-ruby'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']

  #  spec.metadata = {
  #      "changelog_uri" => "",
  #  }

  spec.add_dependency 'concurrent-ruby', '~> 1.1', '>= 1.1.5'
  spec.add_dependency 'opentracing', '~> 0.5.0'
  spec.add_dependency 'wavefront-client'
  spec.add_dependency 'wavefront-metrics'

  spec.add_development_dependency 'test-unit', '~> 3.3'
  spec.add_development_dependency 'bump', '~> 0.5'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rack', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 11.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.16'
  spec.add_development_dependency 'simplecov-console', '~> 0.4.2'
  spec.add_development_dependency 'timecop', '~> 0.8.0'
  spec.add_development_dependency 'rubocop', '~> 0.68.1'


  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')
end
