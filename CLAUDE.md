# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`dlog` is a Ruby CLI tool for appending timestamped entries to daily logs in Obsidian vaults. It provides a DSL for configuring text substitutions, emoji shortcuts, wiki links, and external tool integrations (like Spotify).

## Development Commands

### Testing
```bash
bundle exec rspec                    # Run all tests
bundle exec rspec spec/dsl/          # Run DSL tests only
bundle exec rspec spec/parser/       # Run parser tests only
bundle exec rspec spec/dlog_spec.rb  # Run a specific test file
```

### Running the Tool
```bash
./bin/dlog "Your log entry"          # Append entry to today's log
./bin/dlog-fixup                     # Run in loop mode (watches for changes)
./bin/dlog-fixup --help              # See fixup options (loop mode, delays, etc.)
```

### Installation
```bash
bundle install                       # Install dependencies
chmod +x bin/dlog bin/dlog-fixup    # Make scripts executable
```

## Architecture

### Entry Flow
1. **Input** → `bin/dlog` reads command line args or stdin
2. **Config Loading** → `lib/init.rb` finds and loads config from `~/.config/dlog/vault.rb`
3. **Entry Processing** → `Dsl::Config#process_entry_line` applies substitutions:
   - Time prefix overrides (e.g., `12:34|entry` or `-15|entry`)
   - Prefix substitutions (start of word, e.g., `T` → `✅`)
   - Gsub substitutions (anywhere in text, including blocks)
   - Link substitutions (e.g., `DHH` → `[[David Heinemeier Hansson|DHH]]`)
4. **Timestamp Formatting** → `entry_prefix` proc adds timestamp (e.g., `- *09:45* -`)
5. **File Write** → `Parser::MarkdownLog` manages the markdown file:
   - Finds `# Log` section
   - Splits entries on `⬆︎` prefix if present (allows backdated multi-line entries)
   - Sorts entries by timestamp
   - Deduplicates via SHA256 hash
   - Writes atomically with proper spacing

### Key Components

**DSL System** (`lib/dsl/`):
- `Loader` - Loads and evaluates config files, handles `include` directive
- `Config` - Main config object with DSL methods (`add_prefix`, `add_gsub`, `add_link_gsub`)
- `Substitution` - Handles prefix and gsub replacements, supports Ruby blocks for dynamic content
- `LinkSubstitution` - Special handler for Obsidian `[[page|alias]]` wiki links

**Parser** (`lib/parser/markdown_log.rb`):
- Finds `# Log` section in markdown files
- Extracts entries between section header and next `#` header
- `filter_and_split_entries` - Splits on `⬆︎` prefix for backdated entries
- `sort_entries` - Sorts by extracted timestamp
- Uses SHA256 digest to detect actual changes before writing

**Vault** (`lib/vault.rb`):
- Simple wrapper around config
- `path_to_log(day)` - Calls user-defined `daily_log_finder` proc to locate daily log file
- Validates vault root exists

### Configuration DSL

Users define config at `~/.config/dlog/vault.rb` using these DSL methods:

```ruby
set_vault_root "path"                          # Set Obsidian vault location
set_daily_log_finder { |vault, day| path }    # Define log file path logic
set_entry_prefix { |entry, time| prefix }     # Format timestamp prefix
add_prefix 'TEXT', 'replacement'              # Start-of-word substitution
add_gsub /pattern/, 'replacement'             # Anywhere substitution
add_gsub /pattern/ { |entry, match| result }  # Dynamic substitution with block
add_link_gsub 'TEXT', page: 'Page', alias: 'display'  # Wiki link
include 'filename'                             # Include another config file (no .rb extension)
```

**Block Substitutions**:
- Must accept 2 params: `|entry, match|`
- Return string to replace, `nil` to skip replacement, `""` to delete matched text
- Used for external tools (see `config/vault.example.rb` SONG example)

### Time Prefix Override

Entries can override timestamp using pipe syntax before the main text:
- `12:34|entry` - Absolute time (HH:MM or HHMM)
- `-15|entry` - 15 minutes ago
- `-2h30m|entry` - 2 hours 30 minutes ago
- Parsed in `Dsl::Config#process_entry_line` before other substitutions

### External Tools Integration

The DSL supports calling external scripts:
```ruby
add_gsub /^SONG$/ do |entry|
  set_tool_path '.spotify-song.rb'   # Relative to config dir
  next unless has_tool?              # Skip if tool not found
  run_tool                           # Execute and capture output
  next "❌ Error" if tool_error?     # Check exit code
  tool_output                         # Return output as replacement
end
```

Tool methods available in blocks: `set_tool_path`, `has_tool?`, `run_tool`, `tool_error?`, `tool_output`

## Testing Patterns

- Mock `Dsl::Config` for testing entry processing
- Use `Pathname` for all file paths
- Test files use `spec_helper.rb` which requires `dlog.rb`
- Parser tests use temp files for isolation
- DSL tests verify both simple string replacements and block-based substitutions

## Important Notes

- All file paths use `Pathname` objects, not strings
- Config loading searches 3 locations: `$DLOG_CONFIG`, `~/.config/dlog/vault.rb`, `./vault_config.rb`
- The `# Log` section header is required in markdown files - parser raises error if missing
- Entry sorting uses regex to extract timestamps, assumes format like `*HH:MM*` or `HH:MM`
- Hash-based change detection prevents unnecessary file writes when content is identical
- The `dlog-fixup` tool runs in loop mode with watchdog timer and configurable delays
