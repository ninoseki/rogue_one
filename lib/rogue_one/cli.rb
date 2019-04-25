# frozen_string_literal: true

require "thor"
require "json"

module RogueOne
  class CLI < Thor
    desc "report [DNS_SERVER]", "Show a report of a given DNS server"
    def report(dns_server)
      with_error_handling do
        detector = Detector.new(target: dns_server)
        puts JSON.pretty_generate(detector.report)
      end
    end

    no_commands do
      def with_error_handling
        yield
      rescue StandardError => e
        puts "Warning: #{e}"
      end
    end
  end
end
