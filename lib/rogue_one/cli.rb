# frozen_string_literal: true

require "thor"
require "json"

module RogueOne
  class CLI < Thor
    class << self
      def exit_on_failure?
        true
      end
    end

    desc "report [DNS_SERVER]", "Show a report of a given DNS server"
    method_option :custom_list, type: :string, desc: "A path to a custom list of domains"
    method_option :default_list, type: :string, default: "alexa", desc: "A default list of top 100 domains (Alexa or Fortune)"
    method_option :record_type, type: :string, default: "A", desc: "A type of the DNS resource to check"
    method_option :threshold, type: :numeric, desc: "Threshold value for determining malicious or not"
    method_option :verbose, type: :boolean
    def report(dns_server)
      with_error_handling do
        Ping.pong? dns_server

        custom_list = options["custom_list"]
        default_list = options["default_list"].downcase
        record_type = options["record_type"].upcase
        threshold = options["threshold"]
        verbose = options["verbose"]

        detector = Detector.new(
          custom_list: custom_list,
          default_list: default_list,
          record_type: record_type,
          target: dns_server,
          threshold: threshold,
          verbose: verbose,
        )
        puts JSON.pretty_generate(detector.report)
      end
    end

    no_commands do
      def with_error_handling
        yield
      rescue StandardError => e
        message = { error: e.to_s }
        puts JSON.pretty_generate(message)
      end
    end
  end
end
