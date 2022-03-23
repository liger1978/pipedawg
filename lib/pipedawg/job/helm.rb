# frozen_string_literal: true

module Pipedawg
  class Job
    # Pipedawg::Job::Helm class
    class Helm < Job
      def initialize(name, opts = {})
        opts = {
          command: 'helm',
          image: { entrypoint: [''], name: 'alpine/helm' }
        }.merge(opts)
        super name, opts
      end
    end
  end
end
