# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hfc/version'

Gem::Specification.new do |spec|
  spec.name          = 'hfc'
  spec.version       = HFC::VERSION
  spec.authors       = ['Fabian Stillhart']
  spec.email         = ['fabian.stillhart1@swisscom.com']

  spec.summary       = 'Hierarchial Facts Config - HFC - Generate a config by looking up config based on the given facts in a hierarchical way and deep merge them'
  spec.description   = 'Looks up config fiels in a order and deep merged them together, based on the given facts'
  spec.homepage      = 'https://github.com/swisscom/hfc.git'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  #  spec.metadata["homepage_uri"] = spec.homepage
  #  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  # else
  #  raise "RubyGems 2.0 or newer is required to protect against " \
  #    "public gem pushes."
  # end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = ['hfc']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bump'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'rubocop'
  spec.add_dependency 'activesupport', '>= 4.0'
end
