# frozen_string_literal: true

require "resolv"

module RogueOne
  class Ping
    attr_reader :resolver
    attr_reader :nameserver

    def initialize(nameserver)
      @nameserver = nameserver
      @resolver = Resolv::DNS.new(nameserver: [nameserver])
      @resolver.timeouts = 5
    end

    def get_a_record
      resolver.getresource("example.com", Resolv::DNS::Resource::IN::A)
    rescue Resolv::ResolvError => _e
      nil
    end

    def pong?
      result = get_a_record
      raise Error, "DNS resolve error: there is no resopnse from #{nameserver}" unless result

      true
    end

    def self.pong?(target)
      new(target).pong?
    end
  end
end
