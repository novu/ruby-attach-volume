# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'AWSAttachVolume/version'

Gem::Specification.new do |spec|
  spec.name          = "AWSAttachVolume"
  spec.version       = AWSAttachVolume::VERSION
  spec.authors       = ["Ryan O'Keeffe"]
  spec.email         = ["okeefferd@gmail.com"]

  spec.summary       = "Attaches volumes to running EC2 instances in AWS"
  spec.homepage      = "http://www.github.com/novu/ruby-attach-volume"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 13.0"

  spec.add_dependency "methadone"
  spec.add_dependency "aws-sdk", "~> 2.0"

end
