set_vault_root "~/Documents/Obsidian/vimwiki"

set_daily_log_finder do |vault, day|
  date_path = day.strftime("%Y/%m-%b/%Y-%m-%d-%a.md")
  logs_path = vault.join("logs").join(date_path)
end

set_entry_prefix do |entry|
  ts = Time.now.strftime("%H:%M")
  "- *#{ts}* - "
end

### Emojis
add_gsub ':100:', '💯'

### Prefixes
add_prefix '+1', '👍'

### Personal Projects / Pages
add_link_gsub 'DARTER', '[[dartp6]]'
add_link_gsub 'DARTP6', { alias: 'Sys76 Laptop', page: 'dartp6' } # [[dartp6|Sys76 Laptop]]

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

### Markdown Tool
add_gsub /%%/ do |entry|
  set_tool_path '~/.raycast-cmds/markdown-tool.sh'
  next unless has_tool?

  run_tool
  if tool_error?
    next "❌ MDT-ERROR: #{entry}"
  end

  tool_output
end

