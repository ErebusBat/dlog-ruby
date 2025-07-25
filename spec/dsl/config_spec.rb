require 'spec_helper'

RSpec.describe Dsl::Config do
  let(:loader) { Dsl::Loader.new }

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
            cfg.add_gsub 'KEY' do |entry|
              "YOUR MOM"
            end
          end
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
