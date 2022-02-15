# frozen_string_literal: true

module Pipedawg
  # util class
  class Util
    def self.expand_env_vars(item) # rubocop:disable Metrics/MethodLength
      case item
      when Array
        item.map { |i| expand_env_vars(i) }
      when Hash
        item.each { |k, v| item[k] = expand_env_vars(v) }
        item.transform_keys! { |k| expand_env_vars(k) }
        item
      when String
        item.gsub(/\${([^} ]+)}/) do |e|
          ENV[e.gsub('${', '').gsub('}', '')]
        end
      else
        item
      end
    end

    def self.puts_proxy_vars
      puts 'Proxy settings:'
      puts "http_proxy: #{ENV['http_proxy']}"
      puts "https_proxy: #{ENV['https_proxy']}"
      puts "no_proxy: #{ENV['no_proxy']}"
      puts "HTTP_PROXY: #{ENV['HTTP_PROXY']}"
      puts "HTTPS_PROXY: #{ENV['HTTPS_PROXY']}"
      puts "NO_PROXY: #{ENV['NO_PROXY']}"
    end

    def self.echo_proxy_vars
      script = ['echo Proxy settings:']
      script << 'echo   http_proxy: "${http_proxy}"'
      script << 'echo   https_proxy: "${https_proxy}"'
      script << 'echo   no_proxy: "${no_proxy}"'
      script << 'echo   HTTP_PROXY: "${HTTP_PROXY}"'
      script << 'echo   HTTPS_PROXY: "${HTTPS_PROXY}"'
      script << 'echo   NO_PROXY: "${NO_PROXY}"'
      script
    end
  end
end
