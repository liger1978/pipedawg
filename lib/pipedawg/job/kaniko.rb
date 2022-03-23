# frozen_string_literal: true

module Pipedawg
  class Job
    # Pipedawg::Job::Kaniko class
    class Kaniko < Job
      def initialize(name, opts = {})
        opts = {
          command: '/kaniko/executor',
          image: { entrypoint: [''], name: 'gcr.io/kaniko-project/executor:debug' }
        }.merge(opts)
        super name, opts
      end
    end
  end
end
