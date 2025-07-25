# dlog

A Ruby command-line tool for appending timestamped entries to your daily log in an Obsidian vault.

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

4. (Optional) Add to your PATH:
```bash
ln -s "$(pwd)/bin/dlog" ~/bin/dlog
# or add the bin directory to your PATH
```

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

You can create complex substitutions with Ruby blocks:

```ruby
# Add current weather
add_gsub /^WEATHER$/ do |entry|
  weather = `curl -s "wttr.in?format=%c+%t"`
  "Weather: #{weather.strip}"
end

# Add task ID from environment
add_gsub /TASK:(\w+)/ do |entry, match|
  task_id = match[1]
  "[[Tasks/#{task_id}|Task ##{task_id}]]"
end
```

### Debug Mode

Enable debug output in your configuration:

```ruby
set_debug true
```

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

[Specify your license here]
