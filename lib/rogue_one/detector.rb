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
    attr_reader :target
    attr_reader :default_list
    attr_reader :custom_list
    attr_reader :verbose
    attr_reader :max_concurrency

    GOOGLE_PUBLIC_DNS = "8.8.8.8"

    def initialize(target:, default_list: "alexa", custom_list: nil, threshold: nil, verbose: false)
      @target = target
      @default_list = default_list
      @custom_list = custom_list
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

      { threshold: threshold }
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
      domains

      normal = bulk_resolve(normal_resolver, domains)
      resolutions = bulk_resolve(target_resolver, domains)

      results = resolutions.map do |domain, addresses|
        normal_addresses = normal.dig(domain) || []
        address = (addresses || []).first
        [domain, address] if address && !normal_addresses.include?(address)
      end.compact.to_h

      @memo = results.values.group_by(&:itself).map { |k, v| [k, v.length] }.to_h
      @verbose_memo = results if verbose
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
            records = resolver.query(domain, Resolv::DNS::Resource::IN::A).answer.flatten

            a_records = records.select do |record|
              record.is_a? Resolv::DNS::Resource::IN::A
            end

            addresses = a_records.map do |record|
              record.respond_to?(:address) ? record.address.to_s : nil
            end.compact

            results << [domain, addresses]
          end
        end
      end
      results.to_h.compact
    end

    def normal_resolver
      Async::DNS::Resolver.new([[:udp, GOOGLE_PUBLIC_DNS, 53], [:tcp, GOOGLE_PUBLIC_DNS, 53]])
    end

    def target_resolver
      Async::DNS::Resolver.new([[:udp, target, 53], [:tcp, target, 53]])
    end
  end
end
