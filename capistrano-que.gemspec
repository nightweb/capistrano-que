lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/que/version'

Gem::Specification.new do |spec|
  spec.name = 'capistrano-que'
  spec.version = Capistrano::QueVERSION
  spec.authors = ['Maksim Koritskii','Abdelkader Boudih']
  spec.email = ['max@koritskiy.com', 'terminale@gmail.com']
  spec.description = %q{Que integration for Capistrano}
  spec.summary = %q{Que integration for Capistrano}
  spec.homepage = 'https://github.com/nightweb/capistrano-que'
  spec.license = 'LGPL-3.0'

  spec.required_ruby_version = '>= 2.5.0'

  spec.files = Dir.glob('lib/**/*') + %w(README.md CHANGELOG.md LICENSE.txt)
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '>= 3.9.0'
  spec.add_dependency 'capistrano-bundler'
  spec.add_dependency 'que', '>= 2'
  spec.post_install_message = %q{
    Version 1.0.0 is a major release. Please see README.md, breaking changes are listed in CHANGELOG.md
  }
end
