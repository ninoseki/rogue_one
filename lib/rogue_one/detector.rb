# frozen_string_literal: true

require "yaml"
require "parallel"

module RogueOne
  class Detector
    attr_reader :target
    attr_reader :custom_list

    GOOGLE_PUBLIC_DNS = "8.8.8.8"

    def initialize(target:, custom_list: nil)
      @target = target
      @custom_list = custom_list
      @memo = {}
    end

    def report
      inspect

      { verdict: verdict, landing_pages: landing_pages }
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

    def landing_pages
      @memo.map do |ip, count|
        count > threshold ? ip : nil
      end.compact.sort
    end

    def inspect
      return unless @memo.empty?

      results = Parallel.map(domains) do |domain|
        normal_result = normal_resolver.dig(domain, "A")
        target_result = target_resolver.dig(domain, "A")

        target_result if target_result && normal_result != target_result
      end.compact

      @memo = results.group_by(&:itself).map { |k, v| [k, v.length] }.to_h
    end

    def domains
      @domains ||= custom_domains || top_100_domains
    end

    def custom_domains
      read_domains custom_list
    end

    def top_100_domains
      read_domains File.expand_path("./data/top_100.yml", __dir__)
    end

    def read_domains(path)
      list = DomainList.new(path)
      list.valid? ? list.domains : nil
    end

    def normal_resolver
      @normal_resolver ||= Resolver.new(nameserver: GOOGLE_PUBLIC_DNS)
    end

    def target_resolver
      @target_resolver ||= Resolver.new(nameserver: target)
    end
  end
end
