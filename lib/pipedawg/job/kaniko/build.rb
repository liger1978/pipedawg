# frozen_string_literal: true

module Pipedawg
  class Job
    class Kaniko
      # Pipedawg::Job::Kaniko::Build class
      class Build < Job::Kaniko
        def initialize(name, opts = {}) # rubocop:disable Metrics/MethodLength
          opts = {
            build_args: {},
            config: { '$CI_REGISTRY': { username: '$CI_REGISTRY_USER', password: '$CI_REGISTRY_PASSWORD' } },
            config_file: '/kaniko/.docker/config.json', context: '${CI_PROJECT_DIR}',
            destinations: ['${CI_REGISTRY_IMAGE}:latest'], dockerfile: 'Dockerfile', external_files: {}, flags: [],
            ignore_paths: [], insecure_registries: [], options: {}, registry_certificates: {}, registry_mirrors: [],
            skip_tls_verify_registry: [], trusted_ca_cert_source_files: [],
            trusted_ca_cert_target_file: '/kaniko/ssl/certs/ca-certificates.crt'
          }.merge(opts)
          super name, opts
          update
        end

        def update
          require 'json'
          opts[:script] = debug + config + cert_copies + file_copies + Array(kaniko_cmd)
        end

        private

        def config
          ["echo #{opts[:config].to_json.inspect} > \"#{opts[:config_file]}\""]
        end

        def cert_copies
          Array(opts[:trusted_ca_cert_source_files]).map do |cert|
            "cat \"#{cert}\" >> \"#{opts[:trusted_ca_cert_target_file]}\""
          end
        end

        def file_copies
          opts[:external_files].map do |source, dest|
            "cp \"#{source}\" \"#{opts[:context]}/#{dest}\""
          end
        end

        def kaniko_cmd # rubocop:disable Metrics/AbcSize
          ["\"#{opts[:command]}\" --context \"#{opts[:context]}\"",
           "--dockerfile \"#{opts[:dockerfile]}\"", flags, options, build_args,
           ignore_paths, insecure_registries, registry_certificates, registry_mirrors,
           destinations, skip_tls_verify_registries].reject(&:empty?).join(' ')
        end

        def flags
          flags = opts[:flags].clone
          flags << 'no-push' if opts[:destinations].empty?
          flags.uniq.map { |f| "--#{f}" }.join(' ')
        end

        def options
          opts[:options].map { |k, v| "--#{k}=\"#{v}\"" }.join(' ')
        end

        def build_args
          opts[:build_args].map { |k, v| "--build-arg #{k}=\"#{v}\"" }.join(' ')
        end

        def ignore_paths
          Array(opts[:ignore_paths]).map { |p| "--ignore-path #{p}" }.join(' ')
        end

        def insecure_registries
          Array(opts[:insecure_registries]).map do |r|
            "--insecure-registry #{r}"
          end.join(' ')
        end

        def registry_certificates
          opts[:registry_certificates].map do |k, v|
            "--registry-certificate #{k}=\"#{v}\""
          end.join(' ')
        end

        def registry_mirrors
          Array(opts[:registry_mirrors]).map { |r| "--registry-mirror #{r}" }.join(' ')
        end

        def destinations
          opts[:destinations].map { |d| "--destination #{d}" }.join(' ')
        end

        def skip_tls_verify_registries
          Array(opts[:skip_tls_verify_registry]).map do |r|
            "--skip-tls-verify-registry #{r}"
          end.join(' ')
        end
      end
    end
  end
end
