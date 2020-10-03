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
    method_option :default_list, type: :string, default: "alexa", desc: "A default list of top 100 domains (Alexa or Fortune)"
    method_option :custom_list, type: :string, desc: "A path to a custom list of domains"
    method_option :threshold, type: :numeric, desc: "Threshold value for determining malicious or not"
    method_option :verbose, type: :boolean
    def report(dns_server)
      with_error_handling do
        Ping.pong? dns_server

        default_list = options["default_list"].downcase
        custom_list = options["custom_list"]
        threshold = options["threshold"]
        verbose = options["verbose"]
        detector = Detector.new(target: dns_server, default_list: default_list, custom_list: custom_list, threshold: threshold, verbose: verbose)
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
