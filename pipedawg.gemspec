# frozen_string_literal: true

require_relative 'lib/pipedawg/version'

Gem::Specification.new do |spec|
  spec.name          = 'pipedawg-vl'
  spec.version       = Pipedawg::VERSION
  spec.authors       = ['harbottle']
  spec.email         = ['harbottle@room3d3.com']

  spec.summary       = 'Generate GitLab CI pipelines.'
  spec.description   = 'Generate GitLab CI pipelines.'
  spec.homepage      = 'https://github.com/ValdrinLushaj/pipedawg'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ValdrinLushaj/pipedawg'
  spec.metadata['changelog_uri'] = 'https://github.com/ValdrinLushaj/pipedawg'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f|
      f.match(%r{^(test|spec|features|bin)/}) or
        f.match(%r{^(\.|Rakefile|Gemfile|pipedawg.gemspec)})
    }
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

end
