# frozen_string_literal: true

RSpec.describe RogueOne::CLI do
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end
    result
  end

  describe "#report" do
    let(:mock) { double("detector") }
    let(:report) { { "verdict" => "benign one", "landing_pages" => [] } }

    before do
      allow(mock).to receive(:report).and_return(report)
      allow(RogueOne::Detector).to receive(:new).and_return(mock)
    end

    it do
      stdout = capture(:stdout) { described_class.start %w(report 1.1.1.1) }
      json = JSON.parse(stdout)
      expect(json).to eq(report)
    end

    context "with ping error" do
      before do
        allow(RogueOne::Ping).to receive(:pong?).and_raise("error")
      end

      it do
        stdout = capture(:stdout) { described_class.start %w(report 1.1.1.1) }
        json = JSON.parse(stdout)
        expect(json).to eq("error" => "error")
      end
    end
  end

  describe ".exit_on_failure?" do
    it do
      expect(described_class.exit_on_failure?).to eq(true)
    end
  end
end
