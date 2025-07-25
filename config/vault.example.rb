### Prefixes
add_prefix '+1', '👍'
add_prefix 'CALL', '☎'
add_prefix 'CAR', '🚕'
add_prefix 'CLEAN', '🧹'
add_prefix 'CODE', '💻'
add_prefix 'FEEL', '🧠'
add_prefix 'FOOD', '🍱'
add_prefix 'LEARN', '🧑‍🎓'
add_prefix 'LUNCH', '🍱 Lunch'
add_prefix 'MED', '💊'
add_prefix 'MEET', '👥'
add_prefix 'MEM', '📝'
add_prefix 'REVIEW', '🧐'
add_prefix 'SHOWER', '🚿 Shower'
add_prefix 'T', '✅'
add_prefix 'W', '⚒️'

### Emojis
add_gsub ':100:', '💯'
add_gsub ':bun:', '🐇'
add_gsub ':taco:', '🌮'

### Computers & Servers
add_link_gsub 'NAS', page: 'FreeNAS' # => `[[FreeNAS]]`
add_link_gsub 'M4MBP', alias: 'm4mbp', page: 'MacBook Pro M4'  # => `[[MacBook Pro M4|m4mbp]]`

### People
add_link_gsub 'TIMC', page: 'Tim Cook', alias: 'Tim C. (apple)'
add_link_gsub 'DHH',  page: 'David Heinemeier Hansson', alias: 'DHH'

################################################################################
### External Tools
################################################################################
### Spotify Song
add_gsub /^SONG$/ do |entry|
  set_tool_path '.spotify-song.rb'
  next unless has_tool?

  run_tool
  if tool_error?
    next "❌ Error retriving song: #{song_script_path}"
  end

  if tool_output.empty?
    next "❌ Could not get current song from spotify"
  end

  tool_output
end

################################################################################
### Config & Formatting
################################################################################
set_vault_root "~/Documents/Obsidian/vimwiki"

# Daily Logs in the format of:
# Should return a full path to the log file for the given day
# `vault` will be a Pathname of the vault root
set_daily_log_finder do |vault, day|
  #  <vault>/logs/2025/01-Jan/2025-01-01-Wed.md
  date_path = day.strftime("%Y/%m-%b/%Y-%m-%d-%a.md")
  logs_path = vault.join("logs").join(date_path)
end

# Combines the processesed entity with a given prefix to append
# This is usually to timestamp the entry
set_entry_prefix do |entry, time|
  ts = time.strftime("%H:%M")
  "- *#{ts}* - "
end
