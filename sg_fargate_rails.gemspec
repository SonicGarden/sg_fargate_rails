# frozen_string_literal: true
require_relative "lib/sg_fargate_rails/version"

Gem::Specification.new do |spec|
  spec.name = "sg_fargate_rails"
  spec.version = SgFargateRails::VERSION
  spec.authors = ["interu"]
  spec.email = ["interu@sonicgarden.jp"]

  spec.summary = "rails addon for AWS Fargate"
  spec.description = "for AWS Fargate"
  spec.homepage = "https://github.com/SonicGarden/sg_fargate_rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/SonicGarden/sg_fargate_rails"
  spec.metadata["changelog_uri"] = "https://github.com/SonicGarden/sg_fargate_rails/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html

  spec.add_dependency 'puma'
  spec.add_dependency 'lograge', '~> 0.12'
  spec.add_dependency 'aws-sdk-ec2', '~> 1.413'
  spec.add_dependency 'aws-sdk-scheduler', '~> 1.10'
  spec.add_dependency 'blazer-plus'

  spec.add_development_dependency 'rspec'
end
