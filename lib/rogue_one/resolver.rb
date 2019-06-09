# frozen_string_literal: true

require "resolv"

module RogueOne
  class Resolver
    attr_reader :nameserver

    def initialize(nameserver:)
      @nameserver = nameserver
    end

    def dig(domain, type)
      _resolver.getresource(domain, resource_by_type(type)).address.to_s
    rescue Resolv::ResolvError => e
      nil
    end

    private

    def _resolver
      @_resolver ||= Resolv::DNS.new(nameserver: [nameserver])
      @_resolver.timeouts = 5
      @_resolver
    end

    def resource_by_type(type)
      resources.dig(type.upcase.to_sym)
    end

    def resources
      {
        ANY: Resolv::DNS::Resource::IN::ANY,
        NS: Resolv::DNS::Resource::IN::NS,
        CNAME: Resolv::DNS::Resource::IN::CNAME,
        SOA: Resolv::DNS::Resource::IN::SOA,
        HINFO: Resolv::DNS::Resource::IN::HINFO,
        MINFO: Resolv::DNS::Resource::IN::MINFO,
        MX: Resolv::DNS::Resource::IN::MX,
        TXT: Resolv::DNS::Resource::IN::TXT,
        A: Resolv::DNS::Resource::IN::A,
        WKS: Resolv::DNS::Resource::IN::WKS,
        PTR: Resolv::DNS::Resource::IN::PTR,
        AAAA: Resolv::DNS::Resource::IN::AAAA,
        SRV: Resolv::DNS::Resource::IN::SRV,
      }
    end
  end
end
