# frozen_string_literal: true

module RogueOne
  class Ping
    attr_reader :resolver

    def initialize(nameserver)
      @resolver = Resolver.new(nameserver: nameserver)
    end

    def pong?
      result = resolver.get_resource("example.com", "A")
      raise Error, "DNS resolve error: there is no resopnse from #{resolver.nameserver}" unless result

      true
    end

    def self.pong?(target)
      new(target).pong?
    end
  end
end
