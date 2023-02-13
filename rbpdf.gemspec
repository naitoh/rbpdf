# coding: utf-8
# Copyright (c) 2011-2023 NAITOH Jun
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
  spec.licenses      = ['MIT', 'LGPL-2.1-or-later']
  spec.files         = Dir.glob("lib/rbpdf/version.rb") +
                       Dir.glob("lib/*.rb") +
                       Dir.glob("lib/core/rmagick.rb") +
                       Dir.glob("lib/core/mini_magick.rb") +
                       ["Rakefile", "rbpdf.gemspec", "Gemfile",
                        "CHANGELOG", "test_unicode.rbpdf", "README.md", "LICENSE.TXT", "MIT-LICENSE",
                        "utf8test.txt", "logo_example.png" ]
  spec.rdoc_options  += [ '--exclude', 'lib/core/mini_magick.rb',
                          '--exclude', 'lib/htmlcolors.rb',
                          '--exclude', 'lib/unicode_data.rb' ]

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "htmlentities"
  spec.add_runtime_dependency "rbpdf-font", "~> 1.19.0"
  spec.required_ruby_version = '>= 2.3.0'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "webrick"
end
