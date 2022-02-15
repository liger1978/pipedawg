# frozen_string_literal: true

module Pipedawg
  # qualys_scan_job class
  class QualysScanJob < Job
    attr_accessor :qualys_opts

    def initialize(name = 'build', opts = {}, qualys_opts = {})
      @qualys_opts = {
        acceptable_risk: '${QUALYS_ACCEPTABLE_IMAGE_RISK}',
        artifacts: { expire_in: '1 month', paths: ['software.json', 'vulnerabilities.json'], when: 'always' },
        config: { '$CI_REGISTRY': { username: '$CI_REGISTRY_USER', password: '$CI_REGISTRY_PASSWORD' } },
        debug: true, gateway: '${QUALYS_GATEWAY}', image: nil, password: '${QUALYS_PASSWORD}', rules: nil,
        scan_image: '${QUALYS_IMAGE}', scan_target_prefix: 'qualys_scan_target', tags: nil, user: '${QUALYS_USERNAME}',
        variables: { GIT_STRATEGY: 'clone' }
      }.merge(qualys_opts)
      super name, opts
      update
    end

    def update # rubocop:disable Metrics/AbcSize
      require 'json'
      opts[:artifacts] = qualys_opts[:artifacts] if qualys_opts[:artifacts]
      opts[:image] = qualys_opts[:image]
      opts[:rules] = qualys_opts[:rules] if qualys_opts[:rules]
      opts[:tags] = qualys_opts[:tags] if qualys_opts[:tags]
      opts[:variables] = qualys_opts[:variables] if qualys_opts[:variables]
      opts[:script] = debug + config + image + token + scan_start + scan_complete + artifacts + severities + outputs
    end

    private

    def debug # rubocop:disable Metrics/MethodLength
      if qualys_opts[:debug]
        Pipedawg::Util.echo_proxy_vars + [
          'echo Qualys settings:', "echo   Qualys gateway: \"#{qualys_opts[:gateway]}\"",
          "echo   Qualys username: \"#{qualys_opts[:user]}\"",
          "if [ \"#{qualys_opts[:password]}\" != '' ]; then " \
          'echo   Qualys password is not empty; else ' \
          'echo   Qualys password is not set; exit 1; fi'
        ]
      else
        []
      end
    end

    def config
      ['export CONFIG=$(mktemp -d)', "echo #{qualys_opts[:config].to_json.inspect} > \"${CONFIG}/config.json\""]
    end

    def image
      [
        "image_target=\"#{qualys_opts[:scan_target_prefix]}:$(echo #{qualys_opts[:scan_image]} | sed 's/^[^/]*\\///'| sed 's/[:/]/-/g')\"", # rubocop:disable Layout/LineLength
        "docker --config=\"${CONFIG}\" pull \"#{qualys_opts[:scan_image]}\"",
        "docker image tag \"#{qualys_opts[:scan_image]}\" \"${image_target}\"",
        "image_id=$(docker inspect --format=\"{{index .Id}}\" \"#{qualys_opts[:scan_image]}\" | cut -c8-19)",
        'echo "Image ID: ${image_id}"'
      ]
    end

    def token
      ["token=$(curl -s --location --request POST \"https://#{qualys_opts[:gateway]}/auth\" --header \"Content-Type: application/x-www-form-urlencoded\" --data-urlencode \"username=#{qualys_opts[:user]}\" --data-urlencode \"password=#{qualys_opts[:password]}\" --data-urlencode \"token=true\")"] # rubocop:disable Layout/LineLength
    end

    def scan_start
      [
        'while true; do ' \
        "result=$(curl -s -o /dev/null -w ''%{http_code}'' --location --request GET \"https://#{qualys_opts[:gateway]}/csapi/v1.2/images/$image_id\" --header \"Authorization: Bearer $token\"); " + # rubocop:disable Layout/LineLength, Style/FormatStringToken
          'echo "Waiting for scan to start..."; ' \
          'echo "  Result: ${result}"; ' \
          'if [ "${result}" = "200" ]; then break; fi; ' \
          'sleep 10; done'
      ]
    end

    def scan_complete
      [
        'while true; do ' \
        "result=$(curl -s --location --request GET \"https://#{qualys_opts[:gateway]}/csapi/v1.2/images/$image_id\" --header \"Authorization: Bearer $token\" | jq -r '.scanStatus'); " + # rubocop:disable Layout/LineLength
          'echo "Waiting for scan to complete..."; ' \
          'echo "  Result: ${result}"; ' \
          'if [ "${result}" = "SUCCESS" ]; then break; fi; ' \
          'sleep 10; done; sleep 30'
      ]
    end

    def artifacts
      [
        "curl -s --location --request GET \"https://#{qualys_opts[:gateway]}/csapi/v1.2/images/$image_id/software\" --header \"Authorization: Bearer $token\" | jq . > software.json", # rubocop:disable Layout/LineLength
        "curl -s --location --request GET \"https://#{qualys_opts[:gateway]}/csapi/v1.2/images/$image_id/vuln\" --header \"Authorization: Bearer $token\" | jq . > vulnerabilities.json" # rubocop:disable Layout/LineLength
      ]
    end

    def severities
      [
        "response=$(curl -s --location --request GET \"https://#{qualys_opts[:gateway]}/csapi/v1.2/images/$image_id/vuln/count\" --header \"Authorization: Bearer $token\")", # rubocop:disable Layout/LineLength
        'severity5=$(jq -r ".severity5Count" <<< "${response}")',
        'severity4=$(jq -r ".severity4Count" <<< "${response}")'
      ]
    end

    def outputs # rubocop:disable Metrics/MethodLength
      [
        'if [ "$severity5" = "null" ]; then ' \
        'echo "ERROR: Wrong ImageID or problem during vulnerabilities count." >&2; ' \
        'exit 1; fi',
        'if [ "$severity4" = "null" ]; then ' \
        'echo "ERROR: Wrong ImageID or problem during vulnerabilities count." >&2; ' \
        'exit 1; fi',
        'echo "Severity5: $severity5, Severity4: $severity4"',
        'risk=$((($severity5*3)+($severity4)))',
        'echo "Risk: $risk"',
        "if (($risk > \"#{qualys_opts[:acceptable_risk]}\")); then " \
        'echo "Too many vulnerabilities. Severity5: $severity5, Severity4: $severity4" >&2; ' \
        'exit 1; fi'
      ]
    end
  end
end
