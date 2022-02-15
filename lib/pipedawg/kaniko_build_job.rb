# frozen_string_literal: true

module Pipedawg
  # kaniko_build_job class
  class KanikoBuildJob < Job
    attr_accessor :kaniko_opts

    def initialize(name = 'build', opts = {}, kaniko_opts = {}) # rubocop:disable Metrics/MethodLength
      @kaniko_opts = {
        build_args: {},
        config: {
          '$CI_REGISTRY': { username: '$CI_REGISTRY_USER', password: '$CI_REGISTRY_PASSWORD' }
        },
        config_file: '/kaniko/.docker/config.json', context: '${CI_PROJECT_DIR}', debug: true,
        destinations: [], dockerfile: 'Dockerfile', executor: '/kaniko/executor', external_files: {},
        flags: [], ignore_paths: [], insecure_registries: [],
        image: { entrypoint: [''], name: 'gcr.io/kaniko-project/executor:debug' }, options: {},
        registry_certificates: {}, registry_mirrors: [], skip_tls_verify_registry: [],
        trusted_ca_cert_source_files: [], trusted_ca_cert_target_file: '/kaniko/ssl/certs/ca-certificates.crt'
      }.merge(kaniko_opts)
      super name, opts
      update
    end

    def update # rubocop:disable Metrics/AbcSize
      require 'json'
      opts[:image] = kaniko_opts[:image] if kaniko_opts[:image]
      opts[:script] = debug + config + cert_copies + file_copies + Array(kaniko_cmd)
    end

    private

    def debug
      if kaniko_opts[:debug]
        Pipedawg::Util.echo_proxy_vars
      else
        []
      end
    end

    def config
      ["echo #{kaniko_opts[:config].to_json.inspect} > \"#{kaniko_opts[:config_file]}\""]
    end

    def cert_copies
      Array(kaniko_opts[:trusted_ca_cert_source_files]).map do |cert|
        "cat \"#{cert}\" >> \"#{kaniko_opts[:trusted_ca_cert_target_file]}\""
      end
    end

    def file_copies
      kaniko_opts[:external_files].map do |source, dest|
        "cp \"#{source}\" \"#{kaniko_opts[:context]}/#{dest}\""
      end
    end

    def kaniko_cmd # rubocop:disable Metrics/AbcSize
      ["\"#{kaniko_opts[:executor]}\" --context \"#{kaniko_opts[:context]}\"",
       "--dockerfile \"#{kaniko_opts[:dockerfile]}\"", flags, options, build_args,
       ignore_paths, insecure_registries, registry_certificates, registry_mirrors,
       destinations, skip_tls_verify_registries].reject(&:empty?).join(' ')
    end

    def flags
      flags = kaniko_opts[:flags].clone
      flags << 'no-push' if kaniko_opts[:destinations].empty?
      flags.uniq.map { |f| "--#{f}" }.join(' ')
    end

    def options
      kaniko_opts[:options].map { |k, v| "--#{k}=\"#{v}\"" }.join(' ')
    end

    def build_args
      kaniko_opts[:build_args].map { |k, v| "--build-arg #{k}=\"#{v}\"" }.join(' ')
    end

    def ignore_paths
      Array(kaniko_opts[:ignore_paths]).map { |p| "--ignore-path #{p}" }.join(' ')
    end

    def insecure_registries
      Array(kaniko_opts[:insecure_registries]).map do |r|
        "--insecure-registry #{r}"
      end.join(' ')
    end

    def registry_certificates
      kaniko_opts[:registry_certificates].map do |k, v|
        "--registry-certificate #{k}=\"#{v}\""
      end.join(' ')
    end

    def registry_mirrors
      Array(kaniko_opts[:registry_mirrors]).map { |r| "--registry-mirror #{r}" }.join(' ')
    end

    def destinations
      kaniko_opts[:destinations].map { |d| "--destination #{d}" }.join(' ')
    end

    def skip_tls_verify_registries
      Array(kaniko_opts[:skip_tls_verify_registry]).map do |r|
        "--skip-tls-verify-registry #{r}"
      end.join(' ')
    end
  end
end
