# frozen_string_literal: true

module Pipedawg
  # kaniko_job class
  class KanikoJob < Job
    attr_accessor :kaniko_opts

    def initialize(name = 'build', opts = {}, kaniko_opts = {}) # rubocop:disable Metrics/MethodLength
      @kaniko_opts = {
        build_args: {},
        config: {
          '$CI_REGISTRY': {
            username: '$CI_REGISTRY_USER',
            password: '$CI_REGISTRY_PASSWORD'
          }
        },
        config_file: '/kaniko/.docker/config.json',
        context: '${CI_PROJECT_DIR}',
        destinations: [],
        dockerfile: 'Dockerfile',
        executor: '/kaniko/executor',
        external_files: {},
        flags: [],
        ignore_paths: [],
        insecure_registries: [],
        image: {
          entrypoint: [''],
          name: 'gcr.io/kaniko-project/executor:debug'
        },
        options: {},
        registry_certificates: {},
        registry_mirrors: [],
        skip_tls_verify_registry: [],
        trusted_ca_cert_source_files: [],
        trusted_ca_cert_target_file: '/kaniko/ssl/certs/ca-certificates.crt'
      }.merge(kaniko_opts)
      super name, opts
      update
    end

    def update # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      require 'json'
      opts[:image] = kaniko_opts[:image] if kaniko_opts[:image]
      script = ["echo #{kaniko_opts[:config].to_json.inspect} > \"#{kaniko_opts[:config_file]}\""]
      cert_copies = Array(kaniko_opts[:trusted_ca_cert_source_files]).map do |cert|
        "cat \"#{cert}\" >> \"#{kaniko_opts[:trusted_ca_cert_target_file]}\""
      end
      script.concat cert_copies
      file_copies = kaniko_opts[:external_files].map do |source, dest|
        "cp \"#{source}\" \"#{kaniko_opts[:context]}/#{dest}\""
      end
      script.concat file_copies
      flags = kaniko_opts[:flags].clone
      flags << 'no-push' if kaniko_opts[:destinations].empty?
      flags_cli = flags.uniq.map { |f| "--#{f}" }.join(' ')
      options_cli =  kaniko_opts[:options].map { |k, v| "--#{k}=\"#{v}\"" }.join(' ')
      build_args_cli = kaniko_opts[:build_args].map { |k, v| "--build-arg #{k}=\"#{v}\"" }.join(' ')
      ignore_paths_cli = Array(kaniko_opts[:ignore_paths]).map { |p| "--ignore-path #{p}" }.join(' ')
      insecure_registries_cli = Array(kaniko_opts[:insecure_registries]).map do |r|
        "--insecure-registry #{r}"
      end.join(' ')
      registry_certificates_cli = kaniko_opts[:registry_certificates].map do |k, v|
        "--registry-certificate #{k}=\"#{v}\""
      end.join(' ')
      registry_mirrors_cli = Array(kaniko_opts[:registry_mirrors]).map { |r| "--registry-mirror #{r}" }.join(' ')
      skip_tls_verify_registrys_cli = Array(kaniko_opts[:skip_tls_verify_registry]).map do |r|
        "--skip-tls-verify-registry #{r}"
      end.join(' ')
      destinations_cli = kaniko_opts[:destinations].map { |d| "--destination #{d}" }.join(' ')
      kaniko_cmds = [
        "\"#{kaniko_opts[:executor]}\"",
        '--context',
        "\"#{kaniko_opts[:context]}\"",
        '--dockerfile',
        "\"#{kaniko_opts[:dockerfile]}\"",
        flags_cli,
        options_cli,
        build_args_cli,
        ignore_paths_cli,
        insecure_registries_cli,
        registry_certificates_cli,
        registry_mirrors_cli,
        destinations_cli,
        skip_tls_verify_registrys_cli
      ].reject(&:empty?)
      script << kaniko_cmds.join(' ')
      opts[:script] = script
    end
  end
end
