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
  let(:parsed_entry) { entry = cfg.process_entry_line(input, ts: now) }

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
end
