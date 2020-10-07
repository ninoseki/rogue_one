# frozen_string_literal: true

require "rogue_one/version"

require "rogue_one/domain_list"

require "rogue_one/detector"
require "rogue_one/ping"
require "rogue_one/cli"

module RogueOne
  class Error < StandardError; end
end
