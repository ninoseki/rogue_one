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

    context "with landing pages" do
      let(:memo) { { "9.9.9.9" => 11, "8.8.8.8" => 11, "1.1.1.1" => 11 } }

      before do
        subject.instance_variable_set("@memo", memo)
      end

      it do
        report = subject.report
        expect(report.dig(:landing_pages)).to eq(memo.keys.sort)
      end
    end
  end
end
