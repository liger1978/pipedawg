# frozen_string_literal: true

module Pipedawg
  class Job
    class Helm
      # Pipedawg::Job::Helm::Copy class
      class Copy < Job::Helm
        def initialize(name, opts = {})
          opts = {
            chart: name,
            destinations: [{ user: nil, password: nil, url: nil }],
            password: nil, url: nil, user: nil, version: nil
          }.merge(opts)
          super name, opts
          update
        end

        def update
          opts[:script] = debug + pull + (opts[:destinations].map { |d| push(d) }).flatten(1)
        end

        private

        def pull
          case opts[:url]
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
          if opts[:url] && opts[:chart] && opts[:version]
            script = ['export HELM_EXPERIMENTAL_OCI=1']
            script << login_oci(opts) if opts[:user] && opts[:password]
            script << "\"#{opts[:command]}\" pull \"#{opts[:url]}/#{opts[:chart]}\" --version \"#{opts[:version]}\""
          end
          script
        end

        def push_oci(destination) # rubocop:disable Metrics/AbcSize
          script = []
          if destination[:url] && opts[:chart] && opts[:version]
            script = ['export HELM_EXPERIMENTAL_OCI=1']
            script << login_oci(destination) if destination[:user] && destination[:password]
            script << "\"#{opts[:command]}\" push \"#{opts[:chart]}-#{opts[:version]}.tgz\" \"#{destination[:url]}\""
          end
          script
        end

        def login_oci(login_opts)
          require 'uri'
          "echo \"#{login_opts[:password]}\" | \"#{opts[:command]}\" registry login --username \"#{login_opts[:user]}\" --password-stdin \"#{URI(login_opts[:url]).host}\"" # rubocop:disable Layout/LineLength
        end

        def pull_classic # rubocop:disable Metrics/AbcSize
          script = []
          if opts[:url] && opts[:chart] && opts[:version]
            suffix = login_classic(opts)
            script << "\"#{opts[:command]}\" repo add source \"#{opts[:url]}\"#{suffix}"
            script << "\"#{opts[:command]}\" repo update"
            script << "\"#{opts[:command]}\" pull \"source/#{opts[:chart]}\" --version \"#{opts[:version]}\""
          end
          script
        end

        def push_classic(destination)
          script = []
          if destination[:url] && opts[:chart] && opts[:version]
            script << plugin_classic
            suffix = login_classic(destination)
            script << "\"#{opts[:command]}\" cm-push \"#{opts[:chart]}-#{opts[:version]}.tgz\" \"#{destination[:url]}\"#{suffix}" # rubocop:disable Layout/LineLength
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
          "\"#{opts[:command]}\" plugin list | grep -q cm-push || \"#{opts[:command]}\" plugin install https://github.com/chartmuseum/helm-push"
        end
      end
    end
  end
end
