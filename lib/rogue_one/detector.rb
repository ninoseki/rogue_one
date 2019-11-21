# frozen_string_literal: true

require "yaml"
require "parallel"

module RogueOne
  class Detector
    attr_reader :target
    attr_reader :default_list
    attr_reader :custom_list
    attr_reader :verbose

    GOOGLE_PUBLIC_DNS = "8.8.8.8"

    def initialize(target:, default_list:, custom_list: nil, threshold: nil, verbose: false)
      @target = target
      @default_list = default_list
      @custom_list = custom_list
      @threshold = threshold
      @verbose = verbose

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

      results = Parallel.map(domains) do |domain|
        normal_results = normal_resolver.get_resources(domain, "A")
        target_result = target_resolver.get_resource(domain, "A")

        [domain, target_result] if target_result && !normal_results.include?(target_result)
      end.compact.to_h

      @memo = results.values.group_by(&:itself).map { |k, v| [k, v.length] }.to_h
      @verbose_memo = results if verbose
    end

    def domains
      @domains ||= custom_domains || top_100_domains
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
      else
        raise ArgumentError, "A list for #{default_list} is not existing"
      end
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
