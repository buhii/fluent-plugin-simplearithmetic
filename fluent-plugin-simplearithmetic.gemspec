# coding: utf-8
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-simplearithmetic"
  spec.version       = "0.0.0.pre"
  spec.authors       = ["Takahiro Kamatani"]
  spec.email         = ["buhii314@gmail.com"]
  spec.summary       = %q{TODO: Fluent plugin to calculate messages.}
  spec.description   = %q{TODO: Fluent plugin to calculate messages.}
  spec.homepage      = "https://github.com/buhii/fluent-plugin-simplearithmetic"
  spec.license       = "Apache License, Version 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "fluentd"
  spec.add_runtime_dependency "fluentd"
end
