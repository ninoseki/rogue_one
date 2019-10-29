# frozen_string_literal: true

require "yaml"

module RogueOne
  class DomainList
    attr_reader :path

    def initialize(path)
      @path = path.to_s
    end

    def valid?
      exists? && valid_format?
    end

    def domains
      @domains ||= exists? ? YAML.safe_load(File.read(path)) : nil
    end

    private

    def exists?
      File.exist?(path)
    end

    def valid_format?
      domains.is_a? Array
    end
  end
end
