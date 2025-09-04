require 'pathname'

module Parser
  class MarkdownLog
    def initialize(file_path)
      @file_path = Pathname.new(file_path)
      raise "File not found: #{file_path}" unless @file_path.exist?
    end

    def append_to_log_section(new_entry)
      lines = @file_path.readlines
      log_section_index = find_log_section(lines)

      if log_section_index.nil?
        raise "No '# Log' section found in #{@file_path}"
      end

      # Find the range of lines that belong to the log section
      start_index = log_section_index + 1
      end_index = find_section_end(lines, start_index)

      # Extract log entries
      log_entries = extract_log_entries(lines, start_index, end_index)

      # Add new entry and sort
      log_entries << new_entry unless new_entry.blank?
      log_entries = filter_and_split_entries(log_entries)
      log_entries = sort_entries(log_entries)

      # Rebuild the file content
      new_lines = []
      new_lines.concat(lines[0...start_index])

      # Add sorted entries with proper spacing
      if log_entries.any?
        new_lines << "\n" if start_index > 0 && lines[start_index - 1].strip == "# Log"
        log_entries.each { |entry| new_lines << "#{entry}\n" }
      end

      # Add the rest of the file if there is any
      if end_index < lines.length
        new_lines << "\n" if log_entries.any?
        new_lines.concat(lines[end_index..-1])
      end

      # Write back to file
      @file_path.write(new_lines.join)
    end

    private

    def find_log_section(lines)
      lines.index { |line| line.strip == "# Log" }
    end

    def find_section_end(lines, start_index)
      # Find the next header or EOF
      end_index = start_index
      while end_index < lines.length
        line = lines[end_index].strip
        # Check if we've hit another section header
        break if line.start_with?("#") && !line.empty?
        end_index += 1
      end
      end_index
    end

    def extract_log_entries(lines, start_index, end_index)
      entries = []
      (start_index...end_index).each do |i|
        line = lines[i].strip
        entries << line unless line.empty?
      end
      entries
    end

    def sort_entries(entries)
      entries.sort_by { |entry| entry.downcase }.uniq
    end

    def filter_and_split_entries(entries)
      new_entries = entries.select do |entry|
        entry.match?(/^(- \[ \] )?- \*\d\d:\d\d\* -\s/)
      end

      new_entries.each.with_index do |entry, i|
        old_entry = entry

        # Does entry have two on one line?
        match = nil
        match = entry.match(/^(?<task>- \[ \] )(?<entry>- \*\d\d:\d\d\* -\s.+)\s\(@(?<due_date>20\d\d-\d\d-\d\d)\)$/) unless match.present?
        match = entry.match(/\w(?<entry>\*\d\d:\d\d\* -\s.+)/, 5) unless match.present?
        match = entry.match(/(?<entry>- \*\d\d:\d\d\* -\s.+)/, 1) unless match.present?
        if match.present?
          if match.named_captures.key?("task")
            old_entry = match["entry"]
          end
          new_entry = match["entry"]
          old_entry = entry.sub(new_entry, "")
          if old_entry =~ /^- \[ \]( -)?\s*/
            old_entry = ""
          end
          if old_entry != entry
            new_entries[i] = old_entry
          end
          if !new_entry.blank?
            new_entries << new_entry
          end
        end
      end
      new_entries
    end
  end
end
