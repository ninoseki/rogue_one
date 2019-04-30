# frozen_string_literal: true

RSpec.describe RogueOne::Detector do
  subject { described_class.new(target: "1.1.1.1") }

  describe "#report" do
    before do
      allow(subject).to receive(:top_100_domains).and_return(%w(google.com))
      allow(Parallel).to receive(:processor_count).and_return(0)
    end

    let(:report) { subject.report }

    it do
      expect(report.dig(:verdict)).to eq("benign one")
    end

    it do
      expect(report.dig(:landing_pages)).to eq([])
    end
  end
end
