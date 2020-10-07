# frozen_string_literal: true

require "async"
require "async/barrier"
require "async/dns"
require "async/reactor"
require "async/semaphore"
require "resolv"
require "yaml"
require "etc"

module RogueOne
  class Detector
    attr_reader :custom_list
    attr_reader :default_list
    attr_reader :max_concurrency
    attr_reader :record_type
    attr_reader :target
    attr_reader :verbose

    GOOGLE_PUBLIC_DNS = "8.8.8.8"

    def initialize(target:,
                   custom_list: nil,
                   default_list: "alexa",
                   record_type: "A",
                   threshold: nil,
                   verbose: false)
      @target = target

      @custom_list = custom_list
      @default_list = default_list
      @record_type = record_type.upcase.to_sym
      @threshold = threshold
      @verbose = verbose

      @max_concurrency = Etc.nprocessors * 2
      @memo = {}
      @verbose_memo = nil
    end

    def report
      inspect

      {
        verdict: verdict,
        landing_pages: landing_pages,
        results: results,
        meta: meta
      }.compact
    end

    private

    def verdict
      rogue_one? ? "rogue one" : "benign one"
    end

    def rogue_one?
      !landing_pages.empty?
    end

    def threshold
      @threshold ||= (domains.length.to_f / 10.0).ceil
    end

    def meta
      return nil unless verbose

      {
        record_type: record_type,
        threshold: threshold,
      }
    end

    def landing_pages
      @memo.map do |ip, count|
        count > threshold ? ip : nil
      end.compact.sort
    end

    def results
      return nil unless verbose

      {
        resolutions: resolutions,
        occurrences: occurrences
      }
    end

    def resolutions
      (@verbose_memo || {}).sort_by { |_, v| v }.to_h
    end

    def occurrences
      @memo.sort_by{ |_, v| -v }.to_h
    end

    def inspect
      return unless @memo.empty?

      # read domains outside of the async blocks
      load_domains

      normal_resolutions = bulk_resolve(normal_resolver, domains)
      resolutions = bulk_resolve(target_resolver, domains)

      results = resolutions.map do |domain, addresses|
        normal_addresses = normal_resolutions.dig(domain) || []
        address = (addresses || []).first
        [domain, address] if address && !normal_addresses.include?(address)
      end.compact.to_h

      @memo = results.values.group_by(&:itself).map { |k, v| [k, v.length] }.to_h
      @verbose_memo = results if verbose
    end

    def load_domains
      domains
    end

    def domains
      @domains ||= custom_list ? custom_domains : top_100_domains
    end

    def custom_domains
      read_domains custom_list
    end

    def top_100_domains
      case default_list
      when "alexa"
        read_domains File.expand_path("./data/alexa_100.yml", __dir__)
      when "fortune"
        read_domains File.expand_path("./data/fortune_100.yml", __dir__)
      end
    end

    def read_domains(path)
      list = DomainList.new(path)
      return list.domains if list.valid?

      raise ArgumentError, "Inputted an invalid list. #{path} is not eixst." unless list.exists?
      raise ArgumentError, "Inputted an invalid list. Please input a list as an YAML file." unless list.valid_format?
    end

    def bulk_resolve(resolver, domains)
      results = []

      Async do
        barrier = Async::Barrier.new
        semaphore = Async::Semaphore.new(max_concurrency, parent: barrier)

        domains.each do |domain|
          semaphore.async do
            addresses = []
            begin
              addresses = resolver.addresses_for(domain, dns_resource_by_record_type, { retries: 1 }).map(&:to_s)
            rescue Async::DNS::ResolutionFailure
              # do nothing
            end
            results << [domain, addresses]
          end
        end
      end
      results.to_h
    end

    def normal_resolver
      Async::DNS::Resolver.new([[:udp, GOOGLE_PUBLIC_DNS, 53], [:tcp, GOOGLE_PUBLIC_DNS, 53]])
    end

    def target_resolver
      Async::DNS::Resolver.new([[:udp, target, 53], [:tcp, target, 53]])
    end

    def dns_resource_by_record_type
      @dns_resource_by_record_type ||= dns_resources.dig(record_type)
    end

    def dns_resources
      {
        A: Resolv::DNS::Resource::IN::A,
        AAAA: Resolv::DNS::Resource::IN::AAAA,
      }
    end
  end
end
