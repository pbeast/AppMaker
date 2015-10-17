#!/usr/bin/env ruby

$LOAD_PATH << '.'

require "em-websocket"
require "open3"
require 'json'
require 'colorize'
require 'securerandom'
require 'fileutils'
require 'net/http'
require "uri"

require 'config'

WORKSPACE = File::expand_path("~/Work/Rashim/Rashim.xcworkspace")
PREVIEW_PACKAGES_URL = 'http://6a4df400.ngrok.io'
APPETIZE_API_TOKEN = AppMakerConfig::APPETIZE_API_TOKEN
WORKFOLDER = File::expand_path("~/Work/AppMaker")

def log(ws, status, message)
  response = {:command=> 'log', :status => status, :message => message}
  ws.send response.to_json
end

def response(ws, status, **args)
  resp = {:command=> 'result', :status => status}.merge(args)
  ws.send resp.to_json
end

def upload(scheme, previewsLocation, appetizeApiToken)

  begin
    url = "#{previewsLocation}/#{scheme}/Build/Products/Release-iphonesimulator/#{scheme}.zip"

    #puts url.yellow

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

      return true, json #JSON.pretty_generate(json)
    else
      puts ''
      puts '-----------------------------------------------------------------'
      puts "Response #{response.code} #{response.message}:#{response.body}".red
      puts '-----------------------------------------------------------------'

      return false, { :httpCode => response.code, :httpMessage => response.message, :httpBody => response.body }
    end
  rescue Exception => e
    return false, e.message
  end

end

def preparePreview(request, ws)
  log(ws, 'info', "Got preparePreview command\r")
  t = Thread.new() {
    scheme = request['scheme']
    curDir = Dir.pwd
    tempFolder = File.join(WORKFOLDER, 'Previews', scheme)
    FileUtils::mkdir_p tempFolder


    print 'Building...'
    log(ws, 'info', 'Building. ')
    log(ws, 'info', 'It can take some time...')
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
      log(ws, 'info', "Done\r")

      tempFolder += '/Build/Products/Release-iphonesimulator'

      print 'Making zip...'
      log(ws, 'info', 'Making zip...')
      cmd = `cd '#{tempFolder}' && zip -r -X '#{scheme}.zip' '#{scheme}.app'`
      #puts cmd
      #puts system cmd

      if result==0 then
        puts "Done"
        log(ws, 'info', "Done\r")

        print 'Uploading for preview...'
        log(ws, 'info', 'Uploading for preview...')
        res, response = upload(scheme, PREVIEW_PACKAGES_URL, APPETIZE_API_TOKEN)
        if res
          puts "Done"
          log(ws, 'info', "Done\r")
          response(ws, 'success', :data => response)
        else
          puts "Failed"
          log(ws, 'error', "Failed\r")
          response(ws, 'error', :data => response, :message => 'Failed to upload package')
        end
      else
        puts "Failed"
        log(ws, 'error', "Failed\r")

        response(ws, 'exception', :message => 'Failed to upload package')
      end
    else
      puts 'Failed'
      log(ws, 'error', "Failed\r")
      response(ws, 'exception', :message => 'Failed to build package')
      puts output
    end

    ws.close
  }
  t.run
end

def clean(request, ws)
  begin
    log(ws, 'info', "Got clean command\r")
    t = Thread.new {
      scheme = request['scheme']
      tempFolder = File.join(WORKFOLDER, 'Previews', scheme)

      cmd = "xcodebuild -sdk iphonesimulator -workspace '#{WORKSPACE}' -scheme '#{scheme}' -configuration Release -derivedDataPath '#{tempFolder}' clean"

      exit_status = nil
      log(ws, 'info', "Cleaning...")
      Open3.popen2e(cmd) do |stdin, stdout_and_stderr, thread|
        while outLine=stdout_and_stderr.gets do
          #ws.send outLine
        end

        exit_status = thread.value # Process::Status object returned.
      end

      puts exit_status
      log(ws, 'info', "Done\r")
      response(ws, 'success')
      sleep 1
      ws.close
    }
    t.run
  rescue Exception => e
    response(ws, 'exception', :message => "Failed to clean", :exceptionMessage => e.message)
    ws.close
  end
end

EM.run {
  EM::WebSocket.run(:host => "0.0.0.0", :port => 9090) do |ws|
    ws.onopen { |handshake|
      puts 'WebSocket connection open'

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      #ws.send "Hello Client, you connected to #{handshake.path}\r"

      log(ws, 'info', "Welcome to chuchundra build server...\r\r")
    }

    ws.onclose { puts 'Connection closed' }

    ws.onmessage { |msg|
      begin
        request = JSON.parse(msg)
      rescue  Exception => e
        response(ws, 'exception', :message => 'Invalid request', :exceptionMessage => e.message)
        ws.close
      end

      begin
        if !request.nil?
          puts "Recieved message: #{request}"

          if (request['command'] == "clean")
            clean(request, ws)
          elsif (request['command'] == "preparePreview")
            preparePreview(request, ws)
          else
            puts 'Error: Unknown command'.red
            response(ws, 'error', :message => 'Unknown command')
            ws.close
          end
        end
      rescue Exception => e
        puts "Exception: #{e.message}".red
        response(ws, 'exception', :message => 'Unhandled exception', :exceptionMessage => e.message)
        ws.close
      end
    }
  end
}
