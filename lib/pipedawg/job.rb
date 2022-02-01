# frozen_string_literal: true

module Pipedawg
  # job class
  class Job
    attr_accessor :name, :opts

    def initialize(name = 'build', opts = {}) # rubocop:disable Metrics/MethodLength
      @name = name
      @opts = {
        artifacts: {},
        cache: {},
        image: { name: 'ruby:2.5' },
        needs: [],
        retry: nil,
        rules: nil,
        script: [],
        stage: 'build',
        tags: []
      }.merge(opts)
    end

    def to_hash
      { "#{name}": opts.compact }
    end
  end
end
