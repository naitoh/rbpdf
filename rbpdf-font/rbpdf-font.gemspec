# coding: utf-8
# Copyright (c) 2011-2017 NAITOH Jun
# Released under the MIT license
# http://www.opensource.org/licenses/MIT

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rbpdf-font/version'

Gem::Specification.new do |spec|
  spec.name          = "rbpdf-font"
  spec.version       = RBPDFFontDescriptor::VERSION
  spec.authors       = ["NAITOH Jun"]
  spec.email         = ["naitoh@gmail.com"]
  spec.summary       = %q{RBPDF Font.}
  spec.description   = %q{RBPDF font files.}
  spec.homepage      = ""
  spec.files         = Dir.glob("lib/version.rb") +
                       Dir.glob("lib/rbpdf-font.rb") +
                       Dir.glob("lib/fonts/*.{rb,z}") +
                       Dir.glob("lib/fonts/freefont-*/*") +
                       Dir.glob("lib/fonts/dejavu-fonts-ttf-*/{AUTHORS,BUGS,LICENSE,NEWS,README}") +
                       Dir.glob("lib/fonts/ttf2ufm/*.TXT") +
                       Dir.glob("lib/fonts/ttf2ufm/*.rb") +
                       Dir.glob("lib/fonts/ttf2ufm/ttf2ufm") +
                       Dir.glob("lib/fonts/ttf2ufm/enc/*") +
                       Dir.glob("test/*") +
                       ["Rakefile", "rbpdf-font.gemspec",
                        "CHANGELOG", "README.md", "LICENSE.TXT", "MIT-LICENSE"]
  spec.rdoc_options  += [ '--exclude', 'lib/fonts/' ]

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

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
