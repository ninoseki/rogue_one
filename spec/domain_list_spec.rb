# frozen_string_literal: true

RSpec.describe RogueOne::DomainList do
  describe "#valid?" do
    context "when given an invalid path" do
      subject { described_class.new nil }

      it do
        expect(subject.valid?).to eq(false)
      end
    end

    context "when given a valid path" do
      subject { described_class.new File.expand_path("../lib/rogue_one/data/alexa_100.yml", __dir__) }

      it do
        expect(subject.valid?).to eq(true)
      end
    end
  end

  describe "#domains" do
    context "when given an invalid path" do
      subject { described_class.new nil }

      it do
        expect(subject.domains).to eq(nil)
      end
    end

    context "when given a valid path" do
      subject { described_class.new File.expand_path("../lib/rogue_one/data/alexa_100.yml", __dir__) }

      it do
        expect(subject.domains).to be_an(Array)
      end
    end
  end
end
