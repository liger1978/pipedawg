# frozen_string_literal: true

module Pipedawg
  # helm_copy_job class
  class HelmCopyJob < Job
    attr_accessor :helm_opts

    def initialize(name = 'build', opts = {}, helm_opts = {})
      @helm_opts = {
        chart: name,
        destinations: [{ user: nil, password: nil, url: nil }],
        helm: 'helm',
        image: { entrypoint: [''], name: 'alpine/helm' },
        password: nil, url: nil, user: nil, version: nil
      }.merge(helm_opts)
      super name, opts
      update
    end

    def update
      opts[:image] = helm_opts[:image] if helm_opts[:image]
      opts[:script] = [] + pull + (helm_opts[:destinations].map { |d| push(d) }).flatten(1)
    end

    private

    def pull
      case helm_opts[:url]
      when nil
        []
      when %r{^oci://}
        pull_oci
      else
        pull_classic
      end
    end

    def push(destination)
      case destination[:url]
      when nil
        []
      when %r{^oci://}
        push_oci(destination)
      else
        push_classic(destination)
      end
    end

    def pull_oci # rubocop:disable Metrics/AbcSize
      script = []
      if helm_opts[:url] && helm_opts[:chart] && helm_opts[:version]
        script = ['export HELM_EXPERIMENTAL_OCI=1']
        script << login_oci(helm_opts) if helm_opts[:user] && helm_opts[:password]
        script << "\"#{helm_opts[:helm]}\" pull \"#{helm_opts[:url]}/#{helm_opts[:chart]}\" --version \"#{helm_opts[:version]}\"" # rubocop:disable Layout/LineLength
      end
      script
    end

    def push_oci(destination) # rubocop:disable Metrics/AbcSize
      script = []
      if destination[:url] && helm_opts[:chart] && helm_opts[:version]
        script = ['export HELM_EXPERIMENTAL_OCI=1']
        script << login_oci(destination) if destination[:user] && destination[:password]
        script << "\"#{helm_opts[:helm]}\" push \"#{helm_opts[:chart]}-#{helm_opts[:version]}.tgz\" \"#{destination[:url]}\"" # rubocop:disable Layout/LineLength
      end
      script
    end

    def login_oci(login_opts)
      require 'uri'
      "echo \"#{login_opts[:password]}\" | \"#{helm_opts[:helm]}\" registry login --username \"#{login_opts[:user]}\" --password-stdin \"#{URI(login_opts[:url]).host}\"" # rubocop:disable Layout/LineLength
    end

    def pull_classic # rubocop:disable Metrics/AbcSize
      script = []
      if helm_opts[:url] && helm_opts[:chart] && helm_opts[:version]
        suffix = login_classic(helm_opts)
        script << "\"#{helm_opts[:helm]}\" repo add source \"#{helm_opts[:url]}\"#{suffix}"
        script << "\"#{helm_opts[:helm]}\" repo update"
        script << "\"#{helm_opts[:helm]}\" pull \"source/#{helm_opts[:chart]}\" --version \"#{helm_opts[:version]}\""
      end
      script
    end

    def push_classic(destination)
      script = []
      if destination[:url] && helm_opts[:chart] && helm_opts[:version]
        script << plugin_classic
        suffix = login_classic(destination)
        script << "\"#{helm_opts[:helm]}\" cm-push \"#{helm_opts[:chart]}-#{helm_opts[:version]}.tgz\" \"#{destination[:url]}\"#{suffix}" # rubocop:disable Layout/LineLength
      end
      script
    end

    def login_classic(login_opts)
      if login_opts[:user] && login_opts[:password]
        " --username \"#{login_opts[:user]}\" --password \"#{login_opts[:password]}\""
      else
        ''
      end
    end

    def plugin_classic
      "\"#{helm_opts[:helm]}\" plugin list | grep -q cm-push || \"#{helm_opts[:helm]}\" plugin install https://github.com/chartmuseum/helm-push"
    end
  end
end
