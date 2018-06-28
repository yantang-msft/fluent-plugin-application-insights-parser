lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluent-plugin-application-insights-parser"
  spec.version = "0.1.0"
  spec.authors = ["Microsoft Corporation"]
  spec.email   = ["azure-tools@microsoft.com"]

  spec.summary       = "This is the fluentd parser plugin for Azure Application Insights."
  spec.description   = "Fluentd parser plugin for Azure Application Insights. This plugin is intended to be used with the Http input plugin to parse request sent from Application Insights sdks."

  spec.homepage      = "https://github.com/Microsoft/fluent-plugin-application-insights-parser"
  spec.license       = "MIT"

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files.push('lib/fluent/plugin/parser_application_insights.rb')
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "test-unit", "~> 3.0"
  spec.add_development_dependency "oj", ["~> 2.14"]
  spec.add_runtime_dependency "fluentd", [">= 1.0", "< 2"]
end
