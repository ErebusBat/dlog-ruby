require 'spec_helper'

RSpec.describe Dsl::Config do
  let(:loader) { Dsl::Loader.new }
  let(:cfg) do
    loader.build do |cfg|
      cfg.add_prefix 'W', 'Work'
      cfg.add_gsub ':100:', '💯'
      cfg.add_link_gsub 'PAGE', page: 'Page'
      cfg.set_entry_prefix do |entry, time|
        ts = time.strftime("%H:%M")
        "- [#{ts}] - "
      end
    end
  end
  let(:now) { DateTime.parse("2025-07-25 22:12:45") }  # Friday
  let(:input) { "W on PAGE, :100:" }
  let(:expected) { "Work on [[Page]], 💯" }
  let(:parsed_entry) { cfg.process_entry_line(input, ts: now) }

  it "formats as expected" do
    expect(parsed_entry).to eq "- [22:12] - #{expected}"
  end

  context "timestamp prefix" do
    let(:now) { nil }

    context "accepts HH:SS| prefix" do
      let(:input) { "09:22|W on PAGE, :100:" }
      it "replaces ts in prefix" do
        expect(parsed_entry).to eq "- [09:22] - #{expected}"
      end
    end

    context "accepts HHSS| prefix" do
      let(:input) { "0922|W on PAGE, :100:" }
      it "replaces ts in prefix" do
        expect(parsed_entry).to eq "- [09:22] - #{expected}"
      end
    end
  end

  context "relative timestamp prefix" do
    let(:now) { nil }
    let(:current_time) { Time.parse("2025-07-25 10:30:00") }
    
    before do
      allow(Time).to receive(:now).and_return(current_time)
    end

    context "minutes ago (-12|)" do
      let(:input) { "-12|W on PAGE, :100:" }
      it "calculates time 12 minutes ago" do
        expect(parsed_entry).to eq "- [10:18] - #{expected}"
      end
    end

    context "hours and minutes ago (-1h3m|)" do
      let(:input) { "-1h3m|W on PAGE, :100:" }
      it "calculates time 1 hour 3 minutes ago" do
        expect(parsed_entry).to eq "- [09:27] - #{expected}"
      end
    end

    context "bare number as minutes (-2|)" do
      let(:input) { "-2|W on PAGE, :100:" }
      it "calculates time 2 minutes ago" do
        expect(parsed_entry).to eq "- [10:28] - #{expected}"
      end
    end

    context "just minutes with m suffix (-45m|)" do
      let(:input) { "-45m|W on PAGE, :100:" }
      it "calculates time 45 minutes ago" do
        expect(parsed_entry).to eq "- [09:45] - #{expected}"
      end
    end

    context "just hours with h suffix (-3h|)" do
      let(:input) { "-3h|W on PAGE, :100:" }
      it "calculates time 3 hours ago" do
        expect(parsed_entry).to eq "- [07:30] - #{expected}"
      end
    end
  end
end
