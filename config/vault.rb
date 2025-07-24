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
  song_script_path = Pathname.new("~/bin/.spotify-song.rb").expand_path
  next unless song_script_path.executable?

  script_output = `#{song_script_path.to_s}`.strip
  song_ec = $?.to_i
  if song_ec != 0
    next "❌ Error retriving song: #{song_script_path}"
  end

  song_title =
    if script_output.empty?
      "❌ Could not get current song from spotify"
    else
      script_output
    end
end

### Markdown Tool
add_gsub /%%/ do |entry|
  song_script_path = Pathname.new("~/bin/.spotify-song.rb").expand_path
  next unless song_script_path.executable?

  script_output = `#{song_script_path.to_s}`.strip
  song_ec = $?.to_i
  if song_ec != 0
    next "❌ Error retriving song: #{song_script_path}"
  end

  song_title =
    if script_output.empty?
      "❌ Could not get current song from spotify"
    else
      script_output
    end
end
