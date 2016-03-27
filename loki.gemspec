lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'loki/version'

Gem::Specification.new do |s|
  s.name          = 'loki'
  s.version       = Loki::VERSION
  s.date          = '2016-03-26'

  s.summary       = 'Loki'
  s.description   = 'Quick and dirty static web site generator'

  s.authors       = ['Douglas Triggs']
  s.email         = 'douglas@triggs.org'
  s.homepage      = 'https://github.com/doubt72'

  s.files         = Dir['spec/**/*_spec.rb'] + Dir['lib/**/*.rb']
  s.require_paths = ['spec', 'lib']
  s.bindir        = 'bin'
  s.executables   = ['loki']
end
