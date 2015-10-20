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
require 'timers'

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

def upload(scheme, previewsLocation, appetizeApiToken, privateKey)

  begin
    url = "#{previewsLocation}/#{scheme}/Build/Products/Release-iphonesimulator/#{scheme}.zip"

    #puts url.yellow

    uri = URI('https://api.appetize.io/v1/app/update')
    req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})

    if (privateKey.nil?)
      body = { :token => appetizeApiToken, :url => url, :platform => 'ios' }.to_json
    else
      body = { :token => appetizeApiToken, :url => url, :platform => 'ios', :privateKey => privateKey }.to_json
    end

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
    privateKey = request['privateKey']

    curDir = Dir.pwd
    tempFolder = File.join(WORKFOLDER, 'Previews', scheme)
    FileUtils::mkdir_p tempFolder


    print 'Building...'
    log(ws, 'info', 'Building.')

    progressTimer = EventMachine::PeriodicTimer.new(1) do
      log(ws, 'info', '.')
    end

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

      progressTimer.cancel
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
          log(ws, 'info', 'Uploading for preview.')

          progressTimer = EventMachine::PeriodicTimer.new(1) do
            log(ws, 'info', '.')
          end

          res, response = upload(scheme, PREVIEW_PACKAGES_URL, APPETIZE_API_TOKEN, privateKey)

          progressTimer.cancel
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
        progressTimer.cancel
        puts 'Failed'
        log(ws, 'error', "Failed\r")
        response(ws, 'exception', :message => 'Failed to build package')
        puts output
      end

      ws.close
      }
      t.run
    end

    def submitNewBuild(request, ws)
      begin
        log(ws, 'info', "Got submitNewBuild command\r")
        t = Thread.new {
          begin
            scheme = request['scheme']
            tempFolder = File.join(WORKFOLDER, 'Previews', scheme)
            FileUtils::mkdir_p tempFolder

            cmd = "xcodebuild -workspace '#{WORKSPACE}' -scheme '#{scheme}' PROFILE=af367fcf-16b5-49c3-9c28-e3d563d7abf9 SIGNING='iPhone Distribution: Mobitti Ltd. (P2WQ65BAA8)' -derivedDataPath '#{tempFolder}' -archivePath '#{tempFolder}/#{scheme}' archive"

            exit_status = nil
            log(ws, 'info', "Archiving.")

            progressTimer = EventMachine::PeriodicTimer.new(1) do
              log(ws, 'info', '.')
            end

            Open3.popen2e(cmd) do |stdin, stdout_and_stderr, thread|
              while outLine=stdout_and_stderr.gets do
                  #ws.send outLine
                  puts outLine
                end

                exit_status = thread.value # Process::Status object returned.
              end

              progressTimer.cancel

              puts exit_status
              result = exit_status.to_i
              #puts result

              if result==0 then
                log(ws, 'info', "Done\r")


                ipa = "#{tempFolder}/#{scheme}.ipa"
                FileUtils.rm_f ipa

                cmd = "xcodebuild -exportArchive -archivePath '#{tempFolder}/#{scheme}.xcarchive' -exportPath '#{tempFolder}/#{scheme}'" # -exportOptionsPlist '~/Work/AppMaker/exportPList.plist'

                exit_status = nil
                log(ws, 'info', "Packaging.")

                progressTimer = EventMachine::PeriodicTimer.new(1) do
                  log(ws, 'info', '.')
                end

                Open3.popen2e(cmd) do |stdin, stdout_and_stderr, thread|
                  while outLine=stdout_and_stderr.gets do
                      #ws.send outLine
                      puts outLine
                    end

                    exit_status = thread.value # Process::Status object returned.
                  end

                  progressTimer.cancel

                  puts exit_status
                  result = exit_status.to_i
                  if result==0 then
                    log(ws, 'info', "Done\r")
                    response(ws, 'success')
                  else
                    puts 'Failed'
                    log(ws, 'error', "Failed\r")
                    response(ws, 'exception', :message => 'Failed to export archive')
                  end
                  else
                    puts 'Failed'
                    log(ws, 'error', "Failed\r")
                    response(ws, 'exception', :message => 'Failed to build archive')
                  end
                  ws.close
                rescue Exception => e
                  progressTimer.cancel
                  response(ws, 'exception', :message => "Failed to clean", :exceptionMessage => e.message)
                  ws.close
                end
                }

                t.run
                rescue Exception => e
                  response(ws, 'exception', :message => "Failed to clean", :exceptionMessage => e.message)
                  ws.close
                end
              end

              def clean(request, ws)
                begin
                  log(ws, 'info', "Got clean command\r")
                  t = Thread.new {
                    scheme = request['scheme']
                    tempFolder = File.join(WORKFOLDER, 'Previews', scheme)
                    FileUtils::mkdir_p tempFolder

                    cmd = "xcodebuild -sdk iphonesimulator -workspace '#{WORKSPACE}' -scheme '#{scheme}' -configuration Release -derivedDataPath '#{tempFolder}' clean"

                    exit_status = nil
                    log(ws, 'info', "Cleaning.")

                    progressTimer = EventMachine::PeriodicTimer.new(1) do
                      log(ws, 'info', '.')
                    end

                    Open3.popen2e(cmd) do |stdin, stdout_and_stderr, thread|
                      while outLine=stdout_and_stderr.gets do
                          #ws.send outLine
                        end

                        exit_status = thread.value # Process::Status object returned.
                      end

                      progressTimer.cancel

                      puts exit_status
                      log(ws, 'info', "Done\r")
                      response(ws, 'success')
                      sleep 1
                      ws.close
                      }
                      t.run
                    rescue Exception => e
                      progressTimer.cancel
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
                              elsif (request['command'] == "submitNewBuild")
                                submitNewBuild(request, ws)
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
