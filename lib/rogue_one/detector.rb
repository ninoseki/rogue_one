# frozen_string_literal: true

require "yaml"
require "parallel"

module RogueOne
  class Detector
    attr_reader :target

    GOOGLE_PUBLIC_DNS = "8.8.8.8"

    def initialize(target:)
      @target = target
      @memo = {}
    end

    def report
      @report ||= [].tap do |out|
        inspect

        out << { verdict: verdict, landing_pages: landing_pages }
      end.first
    end

    private

    def verdict
      rogue_one? ? "rogue one" : "benign one"
    end

    def rogue_one?
      !landing_pages.empty?
    end

    def landing_pages
      @memo.map do |ip, count|
        count > 10 ? ip : nil
      end.compact
    end

    def inspect
      results = Parallel.map(top_100_domains) do |domain|
        normal_result = normal_resolver.dig(domain, "A")
        target_result = target_resolver.dig(domain, "A")

        target_result if target_result && normal_result != target_result
      end.compact

      @memo = results.group_by(&:itself).map { |k, v| [k, v.length] }.to_h
    end

    def top_100_domains
      @top_100_domains ||= YAML.safe_load(File.read(File.expand_path("./data/top_100.yml", __dir__)))
    end

    def normal_resolver
      @normal_resolver ||= Resolver.new(nameserver: GOOGLE_PUBLIC_DNS)
    end

    def target_resolver
      @target_resolver ||= Resolver.new(nameserver: target)
    end
  end
end
