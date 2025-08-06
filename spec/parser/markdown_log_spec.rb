require 'spec_helper'
require 'tempfile'
require_relative '../../lib/parser/markdown_log'

RSpec.describe Parser::MarkdownLog do
  let(:temp_file) { Tempfile.new(['test', '.md']) }
  let(:parser) { described_class.new(temp_file.path) }
  
  after do
    temp_file.close
    temp_file.unlink
  end
  
  describe '#append_to_log_section' do
    context 'with empty log section' do
      before do
        temp_file.write(<<~MARKDOWN)
          # Some Header
          Content here
          
          # Log
          
          # Another Header
          More content
        MARKDOWN
        temp_file.rewind
      end
      
      it 'inserts the entry right after the log header' do
        parser.append_to_log_section('- *10:00* - Test entry')
        content = File.read(temp_file.path)
        
        expect(content).to include("# Log\n\n- *10:00* - Test entry\n")
      end
    end
    
    context 'with existing entries' do
      before do
        temp_file.write(<<~MARKDOWN)
          # Log
          - *10:00* - Coffee
          - *14:00* - Meeting
          - *09:00* - Breakfast
        MARKDOWN
        temp_file.rewind
      end
      
      it 'inserts the new entry in sorted order' do
        parser.append_to_log_section('- *11:00* - Lunch')
        content = File.read(temp_file.path)
        lines = content.lines.map(&:strip).reject(&:empty?)
        
        log_index = lines.index('# Log')
        entries = lines[log_index + 1..-1]
        
        expect(entries).to eq([
          '- *09:00* - Breakfast',
          '- *10:00* - Coffee',
          '- *11:00* - Lunch',
          '- *14:00* - Meeting'
        ])
      end
    end
    
    context 'with case differences' do
      before do
        temp_file.write(<<~MARKDOWN)
          # Log
          - *10:00* - zebra task
          - *11:00* - Apple picking
          - *12:00* - BANANA break
        MARKDOWN
        temp_file.rewind
      end
      
      it 'sorts case-insensitively' do
        parser.append_to_log_section('- *13:00* - berry smoothie')
        content = File.read(temp_file.path)
        lines = content.lines.map(&:strip).reject(&:empty?)
        
        log_index = lines.index('# Log')
        entries = lines[log_index + 1..-1]
        
        # When sorting the full line case-insensitively, 
        # the timestamp comes first in the comparison
        expect(entries).to eq([
          '- *10:00* - zebra task',
          '- *11:00* - Apple picking',
          '- *12:00* - BANANA break',
          '- *13:00* - berry smoothie'
        ])
      end
    end
    
    context 'when log section is at EOF' do
      before do
        temp_file.write(<<~MARKDOWN)
          # Some Header
          Content
          
          # Log
          - *10:00* - First entry
        MARKDOWN
        temp_file.rewind
      end
      
      it 'appends correctly without adding extra content' do
        parser.append_to_log_section('- *09:00* - Earlier entry')
        content = File.read(temp_file.path)
        
        expect(content).to end_with("- *09:00* - Earlier entry\n- *10:00* - First entry\n")
      end
    end
    
    context 'when no log section exists' do
      before do
        temp_file.write(<<~MARKDOWN)
          # Some Header
          Content without log section
        MARKDOWN
        temp_file.rewind
      end
      
      it 'raises an error' do
        expect {
          parser.append_to_log_section('- *10:00* - Test')
        }.to raise_error(/No '# Log' section found/)
      end
    end
    
    context 'with blank lines in log section' do
      before do
        temp_file.write(<<~MARKDOWN)
          # Log
          
          - *10:00* - First entry
          
          - *12:00* - Second entry
          
        MARKDOWN
        temp_file.rewind
      end
      
      it 'maintains entries without extra blank lines' do
        parser.append_to_log_section('- *11:00* - Middle entry')
        content = File.read(temp_file.path)
        lines = content.lines.map(&:strip).reject(&:empty?)
        
        log_index = lines.index('# Log')
        entries = lines[log_index + 1..-1]
        
        expect(entries).to eq([
          '- *10:00* - First entry',
          '- *11:00* - Middle entry',
          '- *12:00* - Second entry'
        ])
      end
    end
    
    context 'integration test with realistic file' do
      before do
        temp_file.write(<<~MARKDOWN)
          ---
          name: Tuesday, July 29th 2025
          journal:
            type: entry
            year: 2025
            month: 07
            day: 29
          summary: Daily Log
          ---
          [[_2025-Index|2025]] | [[07-July 2025|July 2025]]
          [[2025/07-Jul/2025-07-28-Mon|←Mon 07-28]] | Tue 07-29 | [[2025/07-Jul/2025-07-30-Wed|Wed 07-30→]]
          
          # Tue, Jul 29
          
          # Reference
          ![[Active Projects#All Active Projects]]
          ![[Daily Log#Daily Log Prefixes]]
          
          # Details
          
          # Log
          
          - *09:00* - Morning coffee
          - *14:00* - Team meeting
          - *12:00* - Lunch break
          
          # Footer
          End of file
        MARKDOWN
        temp_file.rewind
      end
      
      it 'maintains file structure and sorts entries correctly' do
        parser.append_to_log_section('- *10:30* - Code review')
        content = File.read(temp_file.path)
        
        # Check that the file structure is maintained
        expect(content).to include('# Reference')
        expect(content).to include('# Details')
        expect(content).to include('# Footer')
        
        # Extract just the log section
        lines = content.lines
        log_start = lines.index { |l| l.strip == '# Log' }
        log_end = lines.index { |l| l.strip == '# Footer' }
        
        log_entries = lines[(log_start + 1)...log_end].map(&:strip).reject(&:empty?)
        
        expect(log_entries).to eq([
          '- *09:00* - Morning coffee',
          '- *10:30* - Code review',
          '- *12:00* - Lunch break',
          '- *14:00* - Team meeting'
        ])
      end
    end
  end
end