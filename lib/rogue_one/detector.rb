# frozen_string_literal: true

require "yaml"

module RogueOne
  class Detector
    attr_reader :target

    GOOGLE_PUBLIC_DNS = "8.8.8.8"

    def initialize(target:)
      @target = target
      @memo = Hash.new(0)
      @mismatched_domains = []
    end

    def report
      inspect

      {
        verdict: verdict,
        landing_pages: landing_pages
      }
    end

    private

    def verdict
      rogue_one? ? "rogue one" : "benign one"
    end

    def rogue_one?
      @mismatched_domains.length > 50
    end

    def landing_pages
      return [] unless rogue_one?

      @memo.map do |ip, count|
        count > 10 ? ip : nil
      end.compact
    end

    def inspect
      top_100_domains.each do |domain|
        normal_result = normal_resolver.dig(domain, "A")
        target_result = target_resolver.dig(domain, "A")

        if normal_result != target_result
          @mismatched_domains << domain
          @memo[target_result] += 1 if target_result
        end
      end
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
