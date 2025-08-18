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
      log_entries << new_entry
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
  end
end
