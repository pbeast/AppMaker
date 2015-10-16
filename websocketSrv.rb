#!/usr/bin/env ruby

$LOAD_PATH << '.'

require "em-websocket"
require "open3"
require 'json'
require 'colorize'

require 'config'

WORKSPACE = File::expand_path("~/Work/Rashim/Rashim.xcworkspace")
PREVIEWSLOCATION = 'http://cc673dd2.ngrok.io'
APPETIZE_API_TOKEN = AppMakerConfig::APPETIZE_API_TOKEN
WORKFOLDER = File::expand_path("~/Work/AppMaker")

def upload(scheme, previewsLocation, appetizeApiToken)
  url = "#{previewsLocation}/#{scheme}/Build/Products/Release-iphonesimulator/#{scheme}.zip"

  uri = URI('https://api.appetize.io/v1/app/update')
  req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})

  body = { :token => appetizeApiToken, :url => url, :platform => 'ios' }.to_json
  req.body = body

  response = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.ssl_version = :SSLv3
    http.request req
  end

  if response.code=='200' then
    json = JSON.parse response.body

    JSON.pretty_generate(json)
  else
    puts ''
    puts '-----------------------------------------------------------------'
    puts "Response #{response.code} #{response.message}:#{response.body}".red
    puts '-----------------------------------------------------------------'

    500
  end
end

def preparePreview(request, ws)
  ws.send "Got build command\r"
  t = Thread.new() {
    scheme = request['scheme']
    curDir = Dir.pwd
    tempFolder = File.join(WORKFOLDER, 'Previews', scheme)
    #FileUtils::mkdir_p tempFolder


    print 'Building...'
    ws.send 'Building. '
    ws.send 'It can take some time...'
    #output = `xcodebuild -sdk iphonesimulator -WORKSPACE '#{WORKSPACE}' -scheme '#{scheme}' -configuration Release -derivedDataPath '#{tempFolder}'` # > /dev/null 2>&1

    output = ''
    exit_status = nil

    Open3.popen2e("xcodebuild -sdk iphonesimulator -workspace '#{WORKSPACE}' -scheme '#{scheme}' -configuration Release -derivedDataPath '#{tempFolder}'") do |stdin, stdout_and_stderr, thread|
      while outLine=stdout_and_stderr.gets do
        #ws.send outLine
        output += outLine
      end

      exit_status = thread.value # Process::Status object returned.
      #puts exit_status
    end

    #puts output

    result = exit_status.to_i
    #puts result

    if result==0 then
      puts "Done"
      ws.send "Done\r"

      tempFolder += '/Build/Products/Release-iphonesimulator'

      print 'Making zip...'
      ws.send 'Making zip...'
      cmd = `cd '#{tempFolder}' && zip -r -X '#{scheme}.zip' '#{scheme}.app'`
      #puts cmd
      #puts system cmd

      if result==0 then
        puts "Done"
        ws.send "Done\r"

        print 'Uploading for preview...'
        ws.send 'Uploading for preview...'
        #upload(scheme, PREVIEWSLOCATION, APPETIZE_API_TOKEN)
        ws.send "Done\r"
        puts "Done"
      else
        puts "Failed"
        ws.send "Failed\r"
      end
    else
      puts 'Failed'
      ws.send "Failed\r"
      puts output
    end

    ws.close
  }
  t.run
end

def clean(request, ws)
  begin
    ws.send "Got clean command\r"
    t = Thread.new {
      scheme = request['scheme']
      tempFolder = File.join(WORKFOLDER, 'Previews', scheme)

      cmd = "xcodebuild -sdk iphonesimulator -workspace '#{WORKSPACE}' -scheme '#{scheme}' -configuration Release -derivedDataPath '#{tempFolder}' clean"

      exit_status = nil
      ws.send "Cleaning..."
      Open3.popen2e(cmd) do |stdin, stdout_and_stderr, thread|
        while outLine=stdout_and_stderr.gets do
          #ws.send outLine
        end

        exit_status = thread.value # Process::Status object returned.
      end

      puts exit_status
      ws.send "Done\r"
      ws.close
    }
    t.run
  rescue Exception => e
    response = {:error => true, :message => "Failed to clean", :systemMessage => e.message}
    ws.send response.to_json
    ws.close
  end
end

EM.run {
  EM::WebSocket.run(:host => "0.0.0.0", :port => 9090) do |ws|
    ws.onopen { |handshake|
      puts "WebSocket connection open"

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      #ws.send "Hello Client, you connected to #{handshake.path}\r"

      ws.send "Welcome to chuchundra build server...\r\r"
    }

    ws.onclose { puts "Connection closed" }

    ws.onmessage { |msg|

      begin
        request = JSON.parse(msg)
      rescue  Exception => e
        response = {:error => true, :message => "Invalid request", :systemMessage => e.message}
        puts response.to_json

        ws.send response.to_json
        ws.close
      end

      if !request.nil?
        puts "Recieved message: #{request}"

        if (request['command'] == "clean")
          clean(request, ws)
        elsif (request['command'] == "build")
          preparePreview(request, ws)
        else
          response = {:error => true, :message => "Unknown command"}
          ws.send response.to_json
          ws.close
        end
      end
    }
  end
}
