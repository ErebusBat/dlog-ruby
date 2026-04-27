require 'spec_helper'

RSpec.describe Dsl::Config do
  let(:loader) { Dsl::Loader.new }

  context "PatternMatcher" do
    it "wraps regex patterns" do
      pm = Dsl::PatternMatcher.new(/\d+/)
      expect(pm).to be_a(Dsl::PatternMatcher)
      expect(pm.match?("abc123")).to be true
      expect(pm.match?("abc")).to be false
    end

    it "responds to =~" do
      pm = Dsl::PatternMatcher.new(/\d+/)
      expect(pm =~ "abc123").to eq(3)
      expect(pm =~ "abc").to be_nil
    end

    it "converts to regexp" do
      pm = Dsl::PatternMatcher.new(/\d+/)
      expect(pm.to_regexp).to eq(/\d+/)
    end
  end

  context "phone? helper" do
    let(:cfg) do
      loader.build do |cfg|
        cfg.add_gsub cfg.phone? do |entry, match|
          "[#{match}]"
        end
      end
    end

    it "matches 10-digit with dashes" do
      expect(cfg.process_entry_text("Call 123-456-7890"))
        .to eq "Call [123-456-7890]"
    end

    it "matches with parentheses" do
      expect(cfg.process_entry_text("Call (123) 456-7890"))
        .to eq "Call [(123) 456-7890]"
    end

    it "matches with dots" do
      expect(cfg.process_entry_text("Call 123.456.7890"))
        .to eq "Call [123.456.7890]"
    end

    it "matches plain digits" do
      expect(cfg.process_entry_text("Call 1234567890"))
        .to eq "Call [1234567890]"
    end

    it "does not match 7-digit numbers" do
      expect(cfg.process_entry_text("Call 456-7890"))
        .to eq "Call 456-7890"
    end

    it "handles multiple phone numbers" do
      expect(cfg.process_entry_text("Call 123-456-7890 or 987-654-3210"))
        .to eq "Call [123-456-7890] or [987-654-3210]"
    end
  end

  context 'add_prefix' do
    let(:cfg) do
      loader.build do |cfg|
        cfg.add_prefix 'W', 'WORK'
      end
    end

    it "matches" do
      input = "W - Task 1"
      output = cfg.process_entry_text(input)
      expect(output).to eq "WORK - Task 1"
    end

    it "does not match" do
      input = "W- Task 1"
      output = cfg.process_entry_text(input)
      expect(output).to eq "W- Task 1"
    end

    context "stand alone" do
      let(:cfg) do
        loader.build do |cfg|
          cfg.add_prefix 'LUNCH', '🍱 Lunch'
        end
      end

      it "as a prefix" do
        output = cfg.process_entry_text("LUNCH - Food")
        expect(output).to eq "🍱 Lunch - Food"
      end

      it "standalone" do
        output = cfg.process_entry_text("LUNCH")
        expect(output).to eq "🍱 Lunch"
      end
    end
  end

  shared_examples "gsub" do
    it "as only" do
      output = cfg.process_entry_text("#{key_value}")
      expect(output).to eq "#{sub_value}"
    end

    it "as start" do
      output = cfg.process_entry_text("#{key_value} Hello")
      expect(output).to eq "#{sub_value} Hello"
    end

    it "as middle word" do
      output = cfg.process_entry_text("Hello #{key_value} World")
      expect(output).to eq "Hello #{sub_value} World"
    end

    it "in word" do
      output = cfg.process_entry_text("Hello #{key_value}'s World")
      expect(output).to eq "Hello #{sub_value}'s World"
    end

    it "at end" do
      output = cfg.process_entry_text("Hello #{key_value}")
      expect(output).to eq "Hello #{sub_value}"
    end
  end

  context "add_gsub" do
    it_behaves_like "gsub" do
      let(:key_value) { 'TASK' }
      let(:sub_value) { 'Work Task'}
      let(:cfg) do
        loader.build do |cfg|
          cfg.add_gsub key_value, sub_value
        end
      end
    end

    it "strips whitespace" do
      cfg = loader.build do |cfg|
        cfg.add_gsub 'KEY', ' VALUE '
      end
      output = cfg.process_entry_text('KEY')
      expect(output).to eq 'VALUE'
    end

    context "Regexp Matacher" do
      it_behaves_like "gsub" do
        let(:key_value) { 'TASK' }
        let(:sub_value) { 'Work Task'}
        let(:cfg) do
          loader.build do |cfg|
            cfg.add_gsub /TASK/, sub_value
          end
        end
      end
    end

    context "block_given" do
      it_behaves_like "gsub" do
        let(:key_value) { 'KEY' }
        let(:sub_value) { 'YOUR MOM'}
        let(:cfg) do
          loader.build do |cfg|
            cfg.add_gsub 'KEY' do |entry, match|
              "YOUR MOM"
            end
          end
        end
      end

      context "using match parameter" do
        let(:cfg) do
          loader.build do |cfg|
            cfg.add_gsub /CCAM-(\d+)/ do |entry, match|
              issue_num = match.match(/CCAM-(\d+)/)[1]
              "[[https://ccam.atlassian.net/browse/CCAM-#{issue_num}|CCAM-#{issue_num}]]"
            end
          end
        end

        it "uses captured match in replacement" do
          output = cfg.process_entry_text("Working on CCAM-1234 today")
          expect(output).to eq "Working on [[https://ccam.atlassian.net/browse/CCAM-1234|CCAM-1234]] today"
        end

        it "handles multiple matches" do
          output = cfg.process_entry_text("Fixed CCAM-1234 and CCAM-5678")
          expect(output).to eq "Fixed [[https://ccam.atlassian.net/browse/CCAM-1234|CCAM-1234]] and [[https://ccam.atlassian.net/browse/CCAM-5678|CCAM-5678]]"
        end
      end

      context "returning nil for no-op" do
        let(:cfg) do
          loader.build do |cfg|
            cfg.add_gsub /TEST-(\d+)/ do |entry, match|
              issue_num = match.match(/TEST-(\d+)/)[1].to_i
              next if issue_num < 1000  # Don't replace if issue number is less than 1000
              "[[TEST Issue #{issue_num}]]"
            end
          end
        end

        it "leaves text unchanged when block returns nil" do
          output = cfg.process_entry_text("TEST-999 should not change")
          expect(output).to eq "TEST-999 should not change"
        end

        it "replaces when block returns a value" do
          output = cfg.process_entry_text("TEST-1234 should change")
          expect(output).to eq "[[TEST Issue 1234]] should change"
        end
      end

      context "returning empty string to remove text" do
        let(:cfg) do
          loader.build do |cfg|
            cfg.add_gsub /\[REMOVE\]/ do |entry, match|
              ""
            end
          end
        end

        it "removes matched text when block returns empty string" do
          output = cfg.process_entry_text("This [REMOVE] should be gone")
          expect(output).to eq "This  should be gone"
        end
      end
    end
  end

  context "add_link_gsub" do
    context "with string" do
      it_behaves_like "gsub" do
        let(:key_value) { 'PAGE' }
        let(:sub_value) { '[[Page Title]]'}
        let(:cfg) do
          loader.build do |cfg|
            cfg.add_link_gsub key_value, sub_value
          end
        end
      end
    end

    context "with page:" do
      it_behaves_like "gsub" do
        let(:key_value) { 'PAGE' }
        let(:sub_value) { '[[Page Title]]'}
        let(:cfg) do
          loader.build do |cfg|
            cfg.add_link_gsub key_value, page: 'Page Title'
          end
        end
      end
    end

    context "with page: and alias:" do
      it_behaves_like "gsub" do
        let(:key_value) { 'PAGE' }
        let(:sub_value) { '[[Page Title|Alias]]'}
        let(:cfg) do
          loader.build do |cfg|
            cfg.add_link_gsub key_value, page: 'Page Title', alias: 'Alias'
          end
        end
      end
    end
  end
end
