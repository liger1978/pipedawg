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
        debug: true,
        image: { name: 'ruby:2.5' },
        needs: [],
        retry: nil,
        rules: nil,
        script: [],
        stage: 'build',
        tags: [],
        variables: nil
      }.merge(opts)
    end

    def to_hash
      keys = %i[artifacts cache image needs retry rules script stage tags variables]
      { "#{name}": opts.slice(*keys).compact }
    end

    private

    def debug
      if opts[:debug]
        Pipedawg::Util.echo_proxy_vars
      else
        []
      end
    end
  end
end
