# frozen_string_literal: true

module Pipedawg
  class Job
    class Qualys
      # Pipedawg::Job::Qualys::Scan class
      class Scan < Job::Qualys # rubocop:disable Metrics/ClassLength
        def initialize(name, opts = {})
          opts = {
            acceptable_risk: '${QUALYS_ACCEPTABLE_IMAGE_RISK}',
            artifacts: { expire_in: '1 month', paths: ['software.json', 'vulnerabilities.json'], when: 'always' },
            config: { auths: { '$CI_REGISTRY': { username: '$CI_REGISTRY_USER', password: '$CI_REGISTRY_PASSWORD' } } },
            gateway: '${QUALYS_GATEWAY}', image: nil, password: '${QUALYS_PASSWORD}',
            scan_image: '${QUALYS_IMAGE}', scan_target_prefix: 'qualys_scan_target',
            user: '${QUALYS_USERNAME}', variables: { GIT_STRATEGY: 'clone' }
          }.merge(opts)
          super name, opts
          update
        end

        def update # rubocop:disable Metrics/AbcSize
          require 'json'
          opts[:script] =
            debug + config + image + clean_config + token + scan_start +
            scan_complete + artifacts + severities + outputs
        end

        private

        def debug # rubocop:disable Metrics/MethodLength
          if opts[:debug]
            super + [
              'echo Qualys settings:', "echo   Qualys gateway: \"#{opts[:gateway]}\"",
              "echo   Qualys username: \"#{opts[:user]}\"",
              "if [ \"#{opts[:password]}\" != '' ]; then " \
              'echo   Qualys password is not empty; else ' \
              'echo   Qualys password is not set; exit 1; fi'
            ]
          else
            []
          end
        end

        def config
          ['export CONFIG=$(mktemp -d)', "echo #{opts[:config].to_json.inspect} > \"${CONFIG}/config.json\""]
        end

        def image
          [
            "image_target=\"#{opts[:scan_target_prefix]}:$(echo #{opts[:scan_image]} | sed 's/^[^/]*\\///'| sed 's/[:/]/-/g')\"", # rubocop:disable Layout/LineLength
            "docker --config=\"${CONFIG}\" pull \"#{opts[:scan_image]}\"",
            "docker image tag \"#{opts[:scan_image]}\" \"${image_target}\"",
            "image_id=$(docker inspect --format=\"{{index .Id}}\" \"#{opts[:scan_image]}\" | sed 's/sha256://')",
            'echo "Image ID: ${image_id}"'
          ]
        end

        def clean_config
          [
            'rm -f "${CONFIG}/config.json"',
            'rmdir "${CONFIG}"'
          ]
        end

        def token
          ["token=$(curl -s --location --request POST \"https://#{opts[:gateway]}/auth\" --header \"Content-Type: application/x-www-form-urlencoded\" --data-urlencode \"username=#{opts[:user]}\" --data-urlencode \"password=#{opts[:password]}\" --data-urlencode \"token=true\")"] # rubocop:disable Layout/LineLength
        end

        def scan_start
          [
            'while true; do ' \
            "result=$(curl -s -o /dev/null -w ''%{http_code}'' --location --request GET \"https://#{opts[:gateway]}/csapi/v1.3/images/$image_id\" --header \"Authorization: Bearer $token\"); " + # rubocop:disable Layout/LineLength, Style/FormatStringToken
              'echo "Waiting for scan to start..."; ' \
              'echo "  Result: ${result}"; ' \
              'if [ "${result}" = "200" ]; then break; fi; ' \
              'sleep 10; done'
          ]
        end

        def scan_complete
          [
            'while true; do ' \
            "result=$(curl -s --location --request GET \"https://#{opts[:gateway]}/csapi/v1.3/images/$image_id\" --header \"Authorization: Bearer $token\" | jq -r '.scanStatus'); " + # rubocop:disable Layout/LineLength
              'echo "Waiting for scan to complete..."; ' \
              'echo "  Result: ${result}"; ' \
              'if [ "${result}" = "SUCCESS" ]; then break; fi; ' \
              'sleep 10; done; sleep 30'
          ]
        end

        def artifacts
          [
            "curl -s --location --request GET \"https://#{opts[:gateway]}/csapi/v1.3/images/$image_id/software\" --header \"Authorization: Bearer $token\" | jq . > software.json", # rubocop:disable Layout/LineLength
            "curl -s --location --request GET \"https://#{opts[:gateway]}/csapi/v1.3/images/$image_id/vuln\" --header \"Authorization: Bearer $token\" | jq . > vulnerabilities.json" # rubocop:disable Layout/LineLength
          ]
        end

        def severities
          [
            "response=$(curl -s --location --request GET \"https://#{opts[:gateway]}/csapi/v1.3/images/$image_id/vuln/count\" --header \"Authorization: Bearer $token\")", # rubocop:disable Layout/LineLength
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
            "if (($risk > \"#{opts[:acceptable_risk]}\")); then " \
            'echo "Too many vulnerabilities. Severity5: $severity5, Severity4: $severity4" >&2; ' \
            'exit 1; fi'
          ]
        end
      end
    end
  end
end
