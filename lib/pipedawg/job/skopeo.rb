# frozen_string_literal: true

module Pipedawg
  class Job
    # Pipedawg::Job::Skopeo class
    class Skopeo < Job
      def initialize(name, opts = {})
        opts = {
          command: 'skopeo',
          image: { entrypoint: [''], name: 'quay.io/skopeo/stable:latest' }
        }.merge(opts)
        super name, opts
      end
    end
  end
end
