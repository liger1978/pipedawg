# pipedawg

[![Gem Version](https://badge.fury.io/rb/pipedawg.svg)](https://rubygems.org/gems/pipedawg)

Generate GitLab CI pipelines.

## Installation

Install `pipedawg` with:

```
gem install pipedawg
```

Or add this line to your application's Gemfile:

```ruby
gem 'pipedawg'
```

And then execute:

```sh
bundle install
```

## Ruby library

Example:

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pipedawg'

gem_job = Pipedawg::Job.new(
  'build:gem',
  artifacts: ['*.gem'],
  image: 'ruby',
  script: ['bundle install', 'gem build *.gemspec']
)

kaniko_build_job = Pipedawg::Job::Kaniko::Build.new(
  'build:kaniko',
  needs: ['build:gem'],
  retry: 2,
  context:'${CI_PROJECT_DIR}/docker',
  external_files: {'*.gem':'gems'},
  debug: false
)

pipeline = Pipedawg::Pipeline.new 'build:image', jobs: [gem_job, kaniko_build_job]
puts pipeline.to_yaml
pipeline.to_yaml_file('/tmp/pipeline.yaml')
```

```console
$ cat /tmp/pipeline.yaml 
---
stages:
- '1'
- '2'
build:gem:
  artifacts:
  - "*.gem"
  cache: {}
  image: ruby
  needs: []
  script:
  - bundle install
  - gem build *.gemspec
  stage: '1'
  tags: []
build:kaniko:
  artifacts: {}
  cache: {}
  image:
    entrypoint:
    - ''
    name: gcr.io/kaniko-project/executor:debug
  needs:
  - build:gem
  retry: 2
  script:
  - echo "{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}"
    > "/kaniko/.docker/config.json"
  - cp "*.gem" "${CI_PROJECT_DIR}/docker/gems"
  - '"/kaniko/executor" --context "${CI_PROJECT_DIR}/docker" --dockerfile "Dockerfile"
    --destination ${CI_REGISTRY_IMAGE}:latest'
  stage: '2'
  tags: []
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake spec` to run the tests. Run `bundle exec rubocop` to run the linter. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Note that by default, Bundler will attempt to install gems to the system, e.g. `/usr/bin`, `/usr/share`, which requires elevated access and can interfere with files that are managed by the system's package manager. This behaviour can be overridden by creating the file `.bundle/config` and adding the following line:
```
BUNDLE_PATH: "./.bundle"
```
When you run `bin/setup` or `bundle install`, all gems will be installed inside the .bundle directory of this project.

To make this behaviour a default for all gem projects, the above line can be added to the user's bundle config file in their home directory (`~/.bundle/config`)

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/liger1978/pipedawg).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
