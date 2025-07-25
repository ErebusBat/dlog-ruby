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
add_prefix 'REST', '🍃 Rest'
add_prefix 'REVIEW', '🧐'
add_prefix 'SHOWER', '🚿 Shower'
add_prefix 'T', '✅'
add_prefix 'W', '⚒️'

### Emojis
add_gsub ':100:', '💯'
add_gsub ':bee:', '🐝'
add_gsub ':book:', '📖'
add_gsub ':broom:', '🧹'
add_gsub ':bun:', '🐇'
add_gsub ':bus:', '🚌'
add_gsub ':check:', '✅'
add_gsub ':cheese:', '🧀'
add_gsub ':cherries:', '🍒'
add_gsub ':cherry:', '🍒'
add_gsub ':coffee:', '☕️'
add_gsub ':cofin:', '⚰️'
add_gsub ':duck:', '🦆'
add_gsub ':evil:', '😈'
add_gsub ':food:', '🍱'
add_gsub ':hot:', '🥵'
add_gsub ':kiss:', '😘'
add_gsub ':meet:', '🧑‍🤝‍🧑'
add_gsub ':memo:', '📝'
add_gsub ':money:', '💵'
add_gsub ':movie:', '🎬'
add_gsub ':music:', '🎵'
add_gsub ':pen:', '✒️'
add_gsub ':phone:', '☎'
add_gsub ':pill:', '💊'
add_gsub ':pin:', '📌'
add_gsub ':pizza:', '🍕'
add_gsub ':ppcot:', '🙏🍒'
add_gsub ':pray:', '🙏'
add_gsub ':puzzle:', '🧩'
add_gsub ':rofl:', '🤣'
add_gsub ':run:', '🏃'
add_gsub ':school:', '🎓'
add_gsub ':shh:', '🤫'
add_gsub ':shower:', '🚿'
add_gsub ':taco:', '🌮'

### Computers & Servers
add_link_gsub 'DARTER', '[[dartp6]]'
add_link_gsub 'DARTP6', page: 'dartp6'  # [[dartp6|Sys76 Laptop]]
add_link_gsub 'NAS', page: 'FreeNAS'
add_link_gsub 'M4MBP', alias: 'm4mbp', page: 'MacBook Pro M4'
add_link_gsub 'NUC', alias: 'nuc01', page: 'IntelNUC'
add_link_gsub 'MAZE', alias: 'Maze', page: 'IntelNUC 2 - Maze'
add_link_gsub 'THELIO', alias: 'Thelio', page: 'System76 Thelio Deskop'

### CompanyCam - Entities
add_link_gsub 'CCAM', page: 'CompanyCam'
add_link_gsub '16MBP', alias: 'CCAM-16MBP', page: 'CompanyCam 16" MacBook Pro'
add_link_gsub 'PTEAM', alias: 'Platform Team', page: 'CompanyCam Platform Team'

### CompanyCam - People
add_link_gsub 'AUSTIN', page: 'Austin Kostelansky', alias: 'Austin'
add_link_gsub 'COURTNEY', page: 'Courtney White', alias: 'Courtney'
add_link_gsub 'DUSTIN', page: 'Dustin Fisher', alias: 'Dustin'
add_link_gsub 'GREG', page: 'Greg Brinker', alias: 'Greg'
add_link_gsub 'JAREDS', page: 'Jared Stauffer', alias: 'Jared S.'
add_link_gsub 'JASON', page: 'Jason Gaare', alias: 'Jason'
add_link_gsub 'JOSE', page: 'Jose Cartagena', alias: 'Jose'
add_link_gsub 'LEA', page: 'Lea Sheets', alias: 'Lea'
add_link_gsub 'MATT', page: 'Matt Melnick', alias: 'Matt'
add_link_gsub 'MUNYO', page: 'Munyo Frey', alias: 'Munyo'
add_link_gsub 'RACHEL', page: 'Rachel Bryant', alias: 'Rachel'
add_link_gsub 'REID', page: 'Reid Alt', alias: 'Reid'
add_link_gsub 'SHAUN', page: 'Shaun Garwood', alias: 'Shaun'
add_link_gsub 'SILVIA', page: 'Silvia Marmol', alias: 'Silvia'

### CompanyCam - Projects
add_link_gsub 'BLINC', alias: 'Blinc Improvments', page: 'Blinc Improvements Jun 2025'
add_link_gsub 'CAMJAM', alias: 'CamJam', page: 'CamJam 2025'

### Personal Projects / Pages
add_link_gsub 'MDT', alias: '', page: 'Markdown Tool'
add_link_gsub 'TGMD', alias: 'tgmd', page: 'Jira Mark Down Link Tool'

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

################################################################################
### Config & Formatting
################################################################################
set_vault_root "~/Documents/Obsidian/vimwiki"

set_daily_log_finder do |vault, day|
  date_path = day.strftime("%Y/%m-%b/%Y-%m-%d-%a.md")
  logs_path = vault.join("logs").join(date_path)
end

set_entry_prefix do |entry|
  ts = Time.now.strftime("%H:%M")
  "- *#{ts}* - "
end
