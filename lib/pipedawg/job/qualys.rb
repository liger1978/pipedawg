# frozen_string_literal: true

module Pipedawg
  class Job
    # Pipedawg::Job::Qualys class
    class Qualys < Job
      def initialize(name, opts = {})
        super name, opts
      end
    end
  end
end
