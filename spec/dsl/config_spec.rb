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

    context 'auto_space' do
      let(:auto_space) { true }
      let(:cfg) do
        loader.build do |cfg|
          cfg.add_prefix 'T', 'TODO', auto_space: auto_space
        end
      end

      context 'on' do
        it "matches" do
          input = "T - Task 1"
          output = cfg.process_entry_text(input)
          expect(output).to eq "TODO - Task 1"
        end

        it "does not match" do
          input = "T- Task 1"
          output = cfg.process_entry_text(input)
          expect(output).to eq "T- Task 1"
        end
      end

      context 'off' do
        let(:auto_space) { false }

        it "matches" do
          input = "T - Task 1"
          output = cfg.process_entry_text(input)
          expect(output).to eq "TODO - Task 1"
        end

        it "matches part" do
          input = "T- Task 1"
          output = cfg.process_entry_text(input)
          expect(output).to eq "TODO- Task 1"
        end
      end
    end

    context "stand alone prefixes" do
      let(:cfg) do
        loader.build do |cfg|
          cfg.add_prefix 'LUNCH', '🍱 Lunch'
        end
      end

      it "works as a prefix" do
        output = cfg.process_entry_text("LUNCH - Food")
        expect(output).to eq "🍱 Lunch - Food"
      end

      it "works standalone" do
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

    it "in middle word" do
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
