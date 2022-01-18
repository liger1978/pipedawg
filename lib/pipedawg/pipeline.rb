# frozen_string_literal: true

module Pipedawg
  # pipeline class
  class Pipeline
    attr_accessor :name, :opts

    def initialize(name = 'pipeline', opts = {})
      @name = name
      @opts = {
        jobs: [Pipedawg::Job.new],
        stages: ['build'],
        use_stages: true,
        workflow: {}
      }.merge(opts)
    end

    def to_yaml
      require 'json'
      require 'yaml'
      pipeline = opts.compact.reject { |k, _| %i[jobs].include? k }
      opts[:jobs].each do |job|
        pipeline.merge!(job.to_hash)
      end
      JSON.parse(pipeline.to_json).to_yaml
    end

    def to_yaml_file(file = '.gitlab-ci.yml')
      File.write(file, to_yaml)
    end

    def update_stages
      stages = []
      opts[:jobs].each do |job|
        stage = stage_from_needs(opts[:jobs], job)
        stages << stage
        job.opts[:stage] = stage.to_s
      end
      opts[:stages] = stages.uniq.sort.map(&:to_s)
    end

    private

    def stage_from_needs(jobs, job)
      if job.opts.fetch(:needs, []) == []
        1
      else
        job.opts[:needs].map { |need| stage_from_needs(jobs, need) }.max + 1
      end
    end
  end
end
