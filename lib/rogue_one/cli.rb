# frozen_string_literal: true

require "thor"
require "json"

module RogueOne
  class CLI < Thor
    desc "report [DNS_SERVER]", "Show a report of a given DNS server"
    def report(dns_server)
      with_error_handling do
        Ping.pong? dns_server

        detector = Detector.new(target: dns_server)
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
