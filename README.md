# dlog

A Ruby command-line tool for appending timestamped entries to your daily log in an Obsidian vault.

Technically speaking it doesn't have to be an Obsidian vault, any plain text file will do.

## Overview

`dlog` (daily log) is a simple CLI tool that helps you quickly add entries to your daily notes in Obsidian. It supports text substitutions, emoji shortcuts, and can even integrate with external tools to automatically log information like what song you're currently listening to.

## Features

- **Quick Logging**: Append timestamped entries to your daily note with a single command
- **Text Substitutions**: Define shortcuts that expand to frequently used text or emojis
- **Obsidian Wiki Links**: Automatically create properly formatted wiki links with aliases
- **External Tool Integration**: Run scripts to capture dynamic information (e.g., current Spotify song)
- **Modular Configuration**: Split your configuration across multiple files with includes
- **Customizable Paths**: Configure where your daily logs are stored and how they're named
- **Flexible Timestamping**: Customize how timestamps appear in your entries

## Installation

### Development Installation

1. Clone the repository:
```bash
git clone https://github.com/erebusbat/dlog-ruby.git
cd dlog-ruby
```

2. Install dependencies:
```bash
bundle install
```

3. Make the command executable:
```bash
chmod +x bin/dlog
```

4. Add to your PATH:
```bash
ln -s "$(pwd)/bin/dlog" ~/bin/dlog
```

### Production Installation (Recommended)

For daily use, it's recommended to install dlog at `~/.local/share/dlog-ruby` and use the provided wrapper script:

1. Clone to the standard location:
```bash
git clone https://github.com/erebusbat/dlog-ruby.git ~/.local/share/dlog-ruby
cd ~/.local/share/dlog-ruby
bundle install
```

If you use [chezmoi](https://www.chezmoi.io/) then you can put this in your `.chezmoiexternal` file and it will keep the repository up to date:
```toml
["src/erebusbat/dlog-ruby"]
  type = "git-repo"
  url = "https://github.com/ErebusBat/dlog-ruby.git"
  refreshPeriod = "72h"
```

2. Install the wrapper script:
```bash
ln -s ~/.local/share/dlog-ruby/tools/bin_wrapper.sh ~/bin/dlog
```

The wrapper script handles Ruby environment setup (including mise support) automatically. See [Helper Tools](#helper-tools) for more details.

## Configuration

dlog looks for configuration in the following locations (in order):
1. `$DLOG_CONFIG` environment variable
2. `~/.config/dlog/vault.rb`
3. `./vault_config.rb` (current directory)

### Basic Configuration

Create your configuration file based on the example:

```bash
mkdir -p ~/.config/dlog
cp config/vault.example.rb ~/.config/dlog/vault.rb
```

Edit the configuration to match your setup:

```ruby
# Set your Obsidian vault location
set_vault_root "~/Documents/Obsidian/MyVault"

# Configure where daily logs are stored
set_daily_log_finder do |vault, day|
  # This creates paths like: vault/logs/2025/01-Jan/2025-01-01-Wed.md
  date_path = day.strftime("%Y/%m-%b/%Y-%m-%d-%a.md")
  vault.join("logs").join(date_path)
end

# Configure entry timestamp format
set_entry_prefix do |entry, time|
  ts = time.strftime("%H:%M")
  "- *#{ts}* - "
end
```

### Adding Substitutions

#### Prefix Substitutions
Convert short prefixes to longer text or emojis:

```ruby
add_prefix 'T', '✅'              # T Done with task → ✅ Done with task
add_prefix 'MEET', '👥'           # MEET with John → 👥 with John
add_prefix 'LUNCH', '🍱 Lunch'    # LUNCH at cafe → 🍱 Lunch at cafe
```

#### Text Substitutions
Replace text anywhere in your entry:

```ruby
add_gsub ':100:', '💯'            # Great job :100: → Great job 💯
add_gsub ':taco:', '🌮'           # Lunch :taco: → Lunch 🌮
```

#### Wiki Link Substitutions
Create Obsidian wiki links with optional aliases:

```ruby
# Simple link
add_link_gsub 'NAS', page: 'FreeNAS'
# Input: "Configured NAS today" → "Configured [[FreeNAS]] today"

# Link with alias
add_link_gsub 'DHH', page: 'David Heinemeier Hansson', alias: 'DHH'
# Input: "Read article by DHH" → "Read article by [[David Heinemeier Hansson|DHH]]"
```

### Modular Configuration

You can split your configuration across multiple files:

```ruby
# In ~/.config/dlog/vault.rb
set_vault_root "~/Documents/Obsidian/MyVault"

# Include other configuration files
include 'prefixes'    # Loads ~/.config/dlog/prefixes.rb
include 'people'      # Loads ~/.config/dlog/people.rb
include 'tools'       # Loads ~/.config/dlog/tools.rb
```

## Usage

### Basic Usage

```bash
# Add a simple entry
dlog "Had coffee with Sarah"
# Creates: - *09:45* - Had coffee with Sarah

# Using prefix substitutions
dlog "T Finished the report"
# Creates: - *14:30* - ✅ Finished the report

# Using wiki links
dlog "Meeting with DHH about Rails"
# Creates: - *15:00* - Meeting with [[David Heinemeier Hansson|DHH]] about Rails
```

### Time Prefix Overrides

You can override the timestamp for an entry using prefixes:

```bash
# Absolute time prefix (HH:MM or HHMM format)
dlog "12:34|Had lunch"
# Creates: - *12:34* - Had lunch

# Relative time prefix (minutes ago by default)
dlog "-15|Quick phone call"
# Creates: - *09:30* - Quick phone call (if current time is 09:45)

# Relative time with hours
dlog "-2h30m|Started working on project"
# Creates: - *07:15* - Started working on project (if current time is 09:45)

# Other relative formats
dlog "-45m|Coffee break"      # 45 minutes ago
dlog "-1h|Team meeting"       # 1 hour ago
dlog "-90|Long task"          # 90 minutes ago (bare numbers are always minutes)
```

### Multiple Substitutions

Substitutions can be combined:

```bash
dlog "MEET with DHH :100:"
# Creates: - *16:00* - 👥 with [[David Heinemeier Hansson|DHH]] 💯
```

### External Tools

Configure external tools to capture dynamic information:

```ruby
add_gsub /^SONG$/ do |entry|
  set_tool_path '.spotify-song.rb'
  next unless has_tool?

  run_tool
  next "❌ Error retrieving song" if tool_error?

  tool_output
end
```

Then use it:
```bash
dlog "SONG"
# Creates: - *10:30* - 🎵 Now Playing: "Bohemian Rhapsody" by Queen
```

## Advanced Configuration

### Custom Processing

You can create complex substitutions with Ruby blocks. The block receives two parameters:
- `entry`: The full text being processed
- `match`: The matched text from the regex pattern

```ruby
# Add current weather
add_gsub /^WEATHER$/ do |entry, match|
  weather = `curl -s "wttr.in?format=%c+%t"`
  "Weather: #{weather.strip}"
end

# Add task ID from environment - using the match parameter
add_gsub /TASK-(\d+)/ do |entry, match|
  task_id = match.match(/TASK-(\d+)/)[1]
  "[[Tasks/#{task_id}|Task ##{task_id}]]"
end

# Conditional replacement - return nil to skip replacement
add_gsub /ISSUE-(\d+)/ do |entry, match|
  issue_num = match.match(/ISSUE-(\d+)/)[1].to_i
  next if issue_num < 1000  # Don't replace issues below 1000
  "[[https://github.com/org/repo/issues/#{issue_num}|ISSUE-#{issue_num}]]"
end

# Remove text - return empty string to delete matched text
add_gsub /\[REDACTED\]/ do |entry, match|
  ""  # This removes [REDACTED] from the text
end
```

#### Block Return Values

When using blocks with `add_gsub`:
- **Return a string**: Replaces the matched text with the returned string
- **Return `nil`** (via `next` without a value): Leaves the matched text unchanged (no-op)
- **Return `""`** (empty string): Removes the matched text entirely

This allows for conditional processing where you can decide at runtime whether to replace, keep, or remove matched text.

### Debug Mode

Enable debug output in your configuration:

```ruby
set_debug $stderr
```

## Helper Tools

dlog includes helper tools to make integration easier:

### bin_wrapper.sh

A production-ready wrapper script that handles Ruby environment setup:

- **Location**: `tools/bin_wrapper.sh`
- **Purpose**: Sets up the Ruby environment and launches dlog
- **Features**:
  - Automatically activates mise shims if available
  - Expects dlog-ruby to be installed at `~/.local/share/dlog-ruby`
  - Recommended to symlink to `~/bin/dlog` for system-wide access

**Usage**:
```bash
# After installing dlog-ruby at ~/.local/share/dlog-ruby
ln -s ~/.local/share/dlog-ruby/tools/bin_wrapper.sh ~/bin/dlog

# Now you can use dlog from anywhere
dlog "My log entry"
```

### Spotify Integration

Log what you're currently listening to on Spotify:

- **Location**: `tools/spotify-song.rb`
- **Purpose**: Fetches the currently playing track from Spotify and formats it for your log
- **Output Format**: `[🎵 Song Title - Artist Name](spotify-link)`

**Setup**:
1. Create a Spotify app at https://developer.spotify.com/dashboard
2. Create config file at `~/.config/erebusbat/spotify_client.yml`:
   ```yaml
   client_id: your_spotify_client_id
   client_secret: your_spotify_client_secret
   port: 8888  # Optional, defaults to 8888
   ```
3. Add to your dlog configuration:
   ```ruby
   add_gsub /^SONG$/ do |entry|
     set_tool_path 'tools/spotify-song.rb'
     next unless has_tool?

     run_tool
     next "❌ Error retrieving song" if tool_error?

     tool_output
   end
   ```

**First Run**:
- The tool will open your browser for Spotify authorization
- Approve the permissions (only needs read access to currently playing)
- Tokens are saved to `~/.config/erebusbat/spotify_token.yml`
- Authorization only needs to be done once

**Usage**:
```bash
dlog "SONG"
# Creates: - *10:30* - [🎵 Bohemian Rhapsody - Queen](https://open.spotify.com/track/...)
```

**Error Handling**:
- `❌ SONG ERROR: No track currently playing` - Nothing is playing or Spotify is paused
- `❌ SONG ERROR: Access token expired` - Re-authorization needed
- `❌ SONG ERROR: API request failed` - Network or API issues

### Raycast Integration

Quick logging directly from Raycast with keyboard shortcuts:

- **Location**: `tools/raycast-command.sh`
- **Purpose**: Raycast script command for rapid logging
- **Requirements**: Expects the wrapper script to be installed at `~/bin/dlog`

**Installation**:
1. Install dlog and wrapper as described above
2. Open Raycast → Extensions → Script Commands
3. Add the script from `tools/raycast-command.sh`
4. Assign a hotkey (e.g., ⌘⇧L)

**Usage**:
- Trigger your hotkey
- Type your log entry
- Press Enter to append to your daily log

The Raycast integration makes it incredibly fast to log entries without switching contexts.

## Examples

### Daily Workflow

```bash
# Morning
dlog "MORNING Coffee and email"
dlog "T Review yesterday's TODOs"

# Work
dlog "MEET Team standup - discussed API changes"
dlog "CODE Implemented user authentication"
dlog "LUNCH at the new Thai place :100:"

# Evening
dlog "LEARN Ruby metaprogramming concepts"
dlog "SONG"  # Log what you're listening to
```

### Project Tracking

```ruby
# Configure project shortcuts
add_link_gsub 'PROJ1', page: 'Projects/Website Redesign', alias: 'Website'
add_link_gsub 'PROJ2', page: 'Projects/Mobile App', alias: 'App'

# Use them
dlog "W on PROJ1 - fixed navigation bug"
dlog "MEET with client about PROJ2 timeline"
```

## File Structure

Your Obsidian vault will have daily logs organized like:

```
ObsidianVault/
└── logs/
    └── 2025/
        └── 01-Jan/
            ├── 2025-01-01-Wed.md
            ├── 2025-01-02-Thu.md
            └── 2025-01-03-Fri.md
```

Each daily log contains timestamped entries:

```markdown
- *09:00* - ☕ Morning coffee
- *09:30* - ✅ Reviewed emails
- *10:00* - 👥 Team meeting about [[Projects/Q1 Planning|Q1 goals]]
- *12:30* - 🍱 Lunch break
- *14:00* - 💻 Working on [[Projects/API Refactor|API refactor]]
```

## Troubleshooting

### Config File Not Found
- Check that your config file exists at `~/.config/dlog/vault.rb`
- Ensure the file has proper read permissions
- Try setting `DLOG_CONFIG` environment variable to the full path

### Entries Not Appearing
- Verify your vault root path is correct
- Check that the daily log directory structure exists
- Enable debug mode to see where files are being written

### Substitutions Not Working
- Prefix substitutions are case-sensitive and must be at the start of a word
- Link substitutions require exact matches
- Check your configuration syntax - Ruby errors will prevent loading

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

© ErebusBat 2025
