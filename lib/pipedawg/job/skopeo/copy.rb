# frozen_string_literal: true

module Pipedawg
  class Job
    class Skopeo
      # Pipedawg::Job::Skopeo::Copy class
      class Copy < Job::Skopeo
        def initialize(name, opts = {})
          opts = {
            config: {}, copy_image: name, destinations: [{ copy_image: nil, flags: [], options: {} }], flags: [],
            logins: {}, options: {}, stage: '${CI_PROJECT_DIR}/stage', trusted_ca_cert_source_files: [],
            trusted_ca_cert_target_file: '/etc/docker/certs.d/ca.crt'
          }.merge(opts)
          super name, opts
          update
        end

        def update # rubocop:disable Metrics/AbcSize
          require 'json'
          opts[:script] = debug + config + cert_copies + login + mkstage + pull + (
            opts[:destinations].map { |d| push(d) }
          ).flatten(1)
        end

        private

        def config
          ['export CONFIG=$(mktemp -d)', "echo #{opts[:config].to_json.inspect} > \"${CONFIG}/config.json\""]
        end

        def cert_copies
          ["mkdir -p $(dirname \"#{opts[:trusted_ca_cert_target_file]}\")"] +
            Array(opts[:trusted_ca_cert_source_files]).map do |cert|
              "cat \"#{cert}\" >> \"#{opts[:trusted_ca_cert_target_file]}\""
            end
        end

        def login
          opts.fetch(:logins, {}).map do |k, v|
            begin
              command = "echo \"#{v['password']}\" | #{opts[:command]} login --authfile \"${CONFIG}/config.json\" --username \"#{v['username']}\" --password-stdin \"#{k}\"" # rubocop:disable Layout/LineLength
              `#{command}`
              puts "Login succeeded for #{k}"
            rescue RuntimeError => e
              puts "Login failed for #{k}: #{e.message}"
            end
          end
        end

        def mkstage
          ["mkdir -p \"#{opts[:stage]}\""]
        end

        def pull
          copy(opts, "docker://#{opts[:copy_image]}", "\"dir://#{opts[:stage]}\"")
        end

        def push(destination_opts)
          copy(destination_opts, "\"dir://#{opts[:stage]}\"", "docker://#{destination_opts[:copy_image]}")
        end

        def copy(copy_opts, source, destination)
          Array(["#{opts[:command]} copy --authfile \"${CONFIG}/config.json\"", flags(copy_opts), options(copy_opts),
                 source, destination].reject(&:empty?).join(' '))
        end

        def flags(opts)
          opts.fetch(:flags, []).uniq.map { |f| "--#{f}" }.join(' ')
        end

        def options(opts)
          opts.fetch(:options, {}).map { |k, v| "--#{k} \"#{v}\"" }.join(' ')
        end
      end
    end
  end
end
