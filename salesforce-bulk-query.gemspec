# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'salesforce-bulk-query/version'

Gem::Specification.new do |spec|
  spec.name          = "salesforce-bulk-query"
  spec.version       = SalesforceBulkQuery::VERSION
  spec.authors       = ["richet"]
  spec.email         = ["rich@revert.io"]
  spec.summary       = "Used for running batch queries against the Salesforce Bulk API"
  spec.description   = ""
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2"

  spec.add_dependency 'httparty', '~> 0.13.1'
  spec.add_dependency 'oauth2', '~> 0.9.3'
  spec.add_dependency 'addressable', '~>2.3.4'
  spec.add_dependency 'nokogiri', '~> 1.6.2.1'
  spec.add_dependency 'retriable', '~> 1.4'
end
