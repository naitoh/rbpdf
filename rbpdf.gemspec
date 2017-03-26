# coding: utf-8
# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rbpdf/version'

Gem::Specification.new do |spec|
  spec.name          = "rbpdf"
  spec.version       = Rbpdf::VERSION
  spec.authors       = ["NAITOH Jun"]
  spec.email         = ["naitoh@gmail.com"]
  spec.summary       = %q{RBPDF via TCPDF.}
  spec.description   = %q{A template plugin allowing the inclusion of ERB-enabled RBPDF template files.}
  spec.homepage      = ""
  spec.licenses      = ['MIT', 'LGPL 2.1 or later']
  spec.files         = Dir.glob("lib/rbpdf/version.rb") +
                       Dir.glob("lib/*.rb") +
                       Dir.glob("lib/core/rmagick.rb") +
                       Dir.glob("test/*") +
                       ["Rakefile", "rbpdf.gemspec", "Gemfile",
                        "CHANGELOG", "test_unicode.rbpdf", "README.md", "LICENSE.TXT", "MIT-LICENSE",
                        "utf8test.txt", "logo_example.png" ]
  spec.rdoc_options  += [ '--exclude', 'lib/fonts/',
                          '--exclude', 'lib/htmlcolors.rb',
                          '--exclude', 'lib/unicode_data.rb' ]

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  if RUBY_VERSION == "1.8.7"
    spec.add_runtime_dependency "htmlentities", "= 4.3.1"
  else
    spec.add_runtime_dependency "htmlentities"
  end
  spec.add_runtime_dependency "rbpdf-font", "~> 1.19.0"
  spec.required_ruby_version = '>= 1.8.7'

  spec.add_development_dependency "bundler", "~> 1.6"
  if RUBY_VERSION <'1.9.3' # Ruby 1.8.7 or 1.9.2
    spec.add_development_dependency "rake", "<= 10.5"
  else
    spec.add_development_dependency "rake"
  end
  if RUBY_VERSION <'1.9' # Ruby 1.8.7
    spec.add_development_dependency "test-unit", "<= 3.1.5"
  else
    spec.add_development_dependency "test-unit", "~> 3.2"
  end
end
