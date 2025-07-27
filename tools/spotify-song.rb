#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'
require 'yaml'
require 'base64'
require 'fileutils'
require 'webrick'

class SpotifyCurrentTrack
  def initialize
    @config_file = File.expand_path('~/.config/erebusbat/spotify_client.yml')
    @token_file = File.expand_path('~/.config/erebusbat/spotify_token.yml')
    load_config
    @access_token = load_or_refresh_token

    # If we don't have a token and need to start OAuth, do it now
    unless @access_token
      start_oauth_flow
      @access_token = load_or_refresh_token
    end
  end

  def get_current_track_info
    current_track_url = "https://api.spotify.com/v1/me/player/currently-playing"

    uri = URI(current_track_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@access_token}"

    response = http.request(request)

    case response.code
    when '200'
      data = JSON.parse(response.body)

      if data['item'] && data['item']['type'] == 'track'
        track = data['item']
        song_title = track['name']
        artist = track['artists'].map { |a| a['name'] }.join(', ')
        url = track['external_urls']['spotify']

        return "[🎵 #{song_title} - #{artist}](#{url})"
      else
        return "❌ SONG ERROR: No track currently playing"
      end
    when '204'
      return "❌ SONG ERROR: No track currently playing"
    when '401'
      # Try to refresh token if we have a refresh token
      if refresh_access_token
        return get_current_track_info  # Retry with new token
      else
        return "❌ SONG ERROR: Access token expired, please re-authorize"
      end
    else
      return "❌ SONG ERROR: API request failed (#{response.code})"
    end
  rescue => e
    return "❌ SONG ERROR: #{e.message}"
  end

  private

  def load_config
    unless File.exist?(@config_file)
      STDERR.puts "Config file not found: #{@config_file}"
      exit 1
    end

    @config = YAML.load_file(@config_file)
    @client_id = @config['client_id']
    @client_secret = @config['client_secret']
    @port = @config['port'] || 8888

    unless @client_id && @client_secret
      STDERR.puts "client_id and client_secret must be present in #{@config_file}"
      exit 1
    end
  end

  def load_or_refresh_token
    if File.exist?(@token_file)
      token_data = YAML.load_file(@token_file)

      # Check if token is expired (add 5 minute buffer)
      if token_data['expires_at'] && Time.now.to_i < (token_data['expires_at'] - 300)
        return token_data['access_token']
      elsif token_data['refresh_token']
        return refresh_access_token
      end
    end

    # No valid token found, need OAuth flow
    return nil
  end

  def start_oauth_flow
    redirect_uri = "http://localhost:#{@port}/callback"

    auth_url = 'https://accounts.spotify.com/authorize?' + URI.encode_www_form({
      'client_id' => @client_id,
      'response_type' => 'code',
      'redirect_uri' => redirect_uri,
      'scope' => 'user-read-currently-playing'
    })

    puts "Starting OAuth flow..."
    puts "Opening browser to authorize the application..."

    # Start the callback server
    auth_code = start_callback_server(redirect_uri, auth_url)

    if auth_code
      exchange_code_for_token(auth_code, redirect_uri)
    else
      STDERR.puts "Failed to get authorization code"
      exit 1
    end
  end

  def start_callback_server(redirect_uri, auth_url)
    auth_code = nil
    server = nil

    begin
      server = WEBrick::HTTPServer.new(
        Port: @port,
        Logger: WEBrick::Log.new('/dev/null'),
        AccessLog: []
      )

      server.mount_proc '/callback' do |req, res|
        if req.query['code']
          auth_code = req.query['code']
          res.content_type = 'text/html'
          res.body = '<html><body><h1>Authorization successful!</h1><p>You can close this window and return to the terminal.</p></body></html>'
        elsif req.query['error']
          res.content_type = 'text/html'
          res.body = "<html><body><h1>Authorization failed!</h1><p>Error: #{req.query['error']}</p></body></html>"
        else
          res.content_type = 'text/html'
          res.body = '<html><body><h1>Invalid callback</h1><p>No authorization code received.</p></body></html>'
        end

        # Shutdown server after handling the callback
        Thread.new { sleep 1; server.shutdown }
      end

      # Open the authorization URL in the default browser
      system("open '#{auth_url}'") if RUBY_PLATFORM =~ /darwin/
      system("xdg-open '#{auth_url}'") if RUBY_PLATFORM =~ /linux/
      system("start '#{auth_url}'") if RUBY_PLATFORM =~ /mswin|mingw|cygwin/

      puts "If the browser didn't open automatically, visit:"
      puts auth_url
      puts
      puts "Waiting for authorization callback..."

      # Start the server and wait for the callback
      server.start

    rescue Errno::EADDRINUSE
      STDERR.puts "Port #{@port} is already in use. Please choose a different port or stop the service using that port."
      exit 1
    rescue => e
      STDERR.puts "Error starting callback server: #{e.message}"
      exit 1
    ensure
      server&.shutdown
    end

    auth_code
  end

  def exchange_code_for_token(auth_code, redirect_uri)
    token_url = 'https://accounts.spotify.com/api/token'

    credentials = Base64.strict_encode64("#{@client_id}:#{@client_secret}")

    uri = URI(token_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Basic #{credentials}"
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.body = URI.encode_www_form({
      'grant_type' => 'authorization_code',
      'code' => auth_code,
      'redirect_uri' => redirect_uri
    })

    response = http.request(request)

    if response.code == '200'
      data = JSON.parse(response.body)

      token_data = {
        'access_token' => data['access_token'],
        'refresh_token' => data['refresh_token'],
        'expires_at' => Time.now.to_i + data['expires_in']
      }

      # Create directory if it doesn't exist
      FileUtils.mkdir_p(File.dirname(@token_file))

      # Save token data
      File.write(@token_file, token_data.to_yaml)

      puts "Token saved successfully!"
      @access_token = data['access_token']
      return @access_token
    else
      STDERR.puts "Token exchange failed: #{response.code} #{response.message}"
      STDERR.puts response.body
      exit 1
    end
  end

  def refresh_access_token
    return nil unless File.exist?(@token_file)

    token_data = YAML.load_file(@token_file)
    return nil unless token_data['refresh_token']

    token_url = 'https://accounts.spotify.com/api/token'

    credentials = Base64.strict_encode64("#{@client_id}:#{@client_secret}")

    uri = URI(token_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Basic #{credentials}"
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.body = URI.encode_www_form({
      'grant_type' => 'refresh_token',
      'refresh_token' => token_data['refresh_token']
    })

    response = http.request(request)

    if response.code == '200'
      data = JSON.parse(response.body)

      # Update token data
      token_data['access_token'] = data['access_token']
      token_data['expires_at'] = Time.now.to_i + data['expires_in']
      # Keep existing refresh_token if new one isn't provided
      token_data['refresh_token'] = data['refresh_token'] if data['refresh_token']

      File.write(@token_file, token_data.to_yaml)

      @access_token = data['access_token']
      return @access_token
    else
      STDERR.puts "Token refresh failed: #{response.code} #{response.message}"
      return nil
    end
  end
end

# Usage
spotify = SpotifyCurrentTrack.new
result = spotify.get_current_track_info

puts result
