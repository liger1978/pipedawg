# frozen_string_literal: true

module Pipedawg
  # skopeo_copy_job class
  class SkopeoCopyJob < Job
    attr_accessor :skopeo_opts

    def initialize(name = 'build', opts = {}, skopeo_opts = {})
      @skopeo_opts = {
        config: { '$CI_REGISTRY': { username: '$CI_REGISTRY_USER', password: '$CI_REGISTRY_PASSWORD' } },
        copy_image: nil, debug: true, destinations: [{ copy_image: nil, flags: [], options: {} }],
        flags: [], logins: {}, options: {}, skopeo: 'skopeo', stage: '${CI_PROJECT_DIR}/stage',
        image: { entrypoint: [''], name: 'quay.io/skopeo/stable:latest' },
        trusted_ca_cert_source_files: [], trusted_ca_cert_target_file: '/etc/docker/certs.d/ca.crt'
      }.merge(skopeo_opts)
      super name, opts
      update
    end

    def update # rubocop:disable Metrics/AbcSize
      require 'json'
      opts[:image] = skopeo_opts[:image] if skopeo_opts[:image]
      opts[:rules] = skopeo_opts[:rules] if skopeo_opts[:rules]
      opts[:script] = debug + config + cert_copies + login + mkstage + pull + (
        skopeo_opts[:destinations].map { |d| push(d) }
      ).flatten(1)
    end

    private

    def debug
      if skopeo_opts[:debug]
        Pipedawg::Util.echo_proxy_vars
      else
        []
      end
    end

    def config
      ['export CONFIG=$(mktemp -d)', "echo #{skopeo_opts[:config].to_json.inspect} > \"${CONFIG}/config.json\""]
    end

    def cert_copies
      ["mkdir -p $(dirname \"#{skopeo_opts[:trusted_ca_cert_target_file]}\")"] +
        Array(skopeo_opts[:trusted_ca_cert_source_files]).map do |cert|
          "cat \"#{cert}\" >> \"#{skopeo_opts[:trusted_ca_cert_target_file]}\""
        end
    end

    def login
      skopeo_opts.fetch(:logins, {}).map do |k, v|
        "echo \"#{v['password']}\" | #{skopeo_opts[:skopeo]} login --authfile \"${CONFIG}/config.json\" --username \"#{v['username']}\" --password-stdin \"#{k}\"" # rubocop:disable Layout/LineLength
      end
    end

    def mkstage
      ["mkdir -p \"#{skopeo_opts[:stage]}\""]
    end

    def pull
      copy(skopeo_opts, "docker://#{skopeo_opts[:copy_image]}", "\"dir://#{skopeo_opts[:stage]}\"")
    end

    def push(destination_opts)
      copy(destination_opts, "\"dir://#{skopeo_opts[:stage]}\"", "docker://#{destination_opts[:copy_image]}")
    end

    def copy(opts, source, destination)
      Array(["#{skopeo_opts[:skopeo]} copy --authfile \"${CONFIG}/config.json\"", flags(opts), options(opts), source,
             destination].reject(&:empty?).join(' '))
    end

    def flags(opts)
      opts.fetch(:flags, []).uniq.map { |f| "--#{f}" }.join(' ')
    end

    def options(opts)
      opts.fetch(:options, {}).map { |k, v| "--#{k} \"#{v}\"" }.join(' ')
    end
  end
end
