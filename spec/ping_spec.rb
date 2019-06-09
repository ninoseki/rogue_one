# frozen_string_literal: true

RSpec.describe RogueOne::Ping do
  subject { described_class.new("1.1.1.1") }

  describe "#pong?" do
    it do
      expect(subject.pong?).to eq(true)
    end
  end
end
