require 'sinatra'
require 'json'
require 'securerandom'
require 'fileutils'
require 'net/http'
require "uri"
require 'colorize'

set :port, 1234

$stdout.sync = true

workspace = File::expand_path("~/Work/Rashim/Rashim.xcworkspace")

#previews = "/Volumes/Macintosh\ HD/Users/pbeast/Tmp/Previews/"


def camel_case(str)
  words = str.downcase.split
  words.shift + words.map(&:capitalize).join
end

#use Rack::Auth::Basic do |username, password|
#  username == 'admin' && password == 'secret'
#end

get '/' do
    'Welcome to app maker service'
end


def upload(scheme)
  url = "http://4df57fac.ngrok.io/#{scheme}/Build/Products/Release-iphonesimulator/#{scheme}.zip"

  uri = URI('https://api.appetize.io/v1/app/update')
  req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})

  body = { :token => 'tok_p5451b2aep2cpzjnj1rdt647pg', :url => url, :platform => 'ios' }.to_json
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
    puts '-----------------------------------------------------------------'
    puts "Response #{response.code} #{response.message}:#{response.body}".red
    puts '-----------------------------------------------------------------'

    500
  end
end

get '/upload/:scheme' do
  scheme = params['scheme']

  upload (scheme)
end

get '/build/:scheme' do
  scheme = params['scheme']
  curDir = Dir.pwd
  tempFolder = File.join(Dir.pwd, "Previews", scheme)

  FileUtils::mkdir_p tempFolder

  print 'Building...'.green
  cmd = `xcodebuild -sdk iphonesimulator -workspace '#{workspace}' -scheme '#{scheme}' -configuration Release -derivedDataPath '#{tempFolder}' > /dev/null 2>&1`
  #system cmd

  result = $?.to_i
#  puts result

  if result==0 then
    puts "Done".green

    tempFolder += '/Build/Products/Release-iphonesimulator'

    print 'Making zip...'.green
    cmd = `cd '#{tempFolder}' && zip -r -X '#{scheme}.zip' '#{scheme}.app'`
    #puts cmd
    #puts system cmd

    if result==0 then
      puts "Done".green

      print 'Uploading for preview...'.green
      upload(scheme)
    else
      puts "Failed".red
      500
    end
  else
    puts 'Failed'.red
    500
  end
end

get '/clean/:scheme' do
  scheme = params['scheme']

  output = `xcodebuild  -workspace "#{workspace}" -scheme '#{scheme}' clean`
  puts output
end

get '/schemes' do
  schemesPattern = "Schemes:"
  output = `xcodebuild -workspace '#{workspace}' -list`
  index = output.index(schemesPattern)
  if !index.nil?
    headers \
      "Content-Type" => "application/json;charset=utf-8"
    output = output[index + schemesPattern.length, output.length - schemesPattern.length].strip
    output.gsub! '  ', ''
    
    schemes = output.lines
    schemes.map! { |s| 
      s.gsub "\n", ''
    }
    JSON.pretty_generate(schemes)
  else
    404
  end
end

#get '/hi' do
#  'Hello World!'
#end

#get '/hello/:name/:prefix' do
#  # matches "GET /hello/foo" and "GET /hello/bar"
#  # params['name'] is 'foo' or 'bar'
#  name = params['name']
#  name = camel_case(name)
#  "Hello #{params['prefix']}.#{name}!"
#end