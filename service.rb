require 'sinatra'
require 'json'
require 'securerandom'
require 'fileutils'
require 'net/http'
require "uri"

set :port, 1234

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

get '/upload/:scheme' do
  scheme = params['scheme']
  url = "http://775235af.ngrok.io/#{scheme}/Build/Products/Release-iphonesimulator/#{scheme}.zip"

  uri = URI.parse("https://api.appetize.io")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new('/v1/app/update')
  #request.set_form_data({ "token" => "tok_p5451b2aep2cpzjnj1rdt647pg", "url" => url, "platform" => "ios" })
  request.body = { 'token' => 'tok_p5451b2aep2cpzjnj1rdt647pg', 'url' => url, 'platform' => 'ios' }.to_json
  response = http.request(request)

  #req = Net::HTTP::Post.new('/v1/app/update', initheader = {'Content-Type' =>'application/json'})
  #req.body = { "token" => "tok_p5451b2aep2cpzjnj1rdt647pg", "url" => url, "platform" => "ios" }.to_json
  #response = Net::HTTP.new('https://api.appetize.io', '443').start {|http| http.request(req) }
  puts '-----------------------------------------------------------------'
  puts "Response #{response.code} #{response.message}:#{response.body}"
  puts '-----------------------------------------------------------------'
end

get '/build/:scheme' do
  scheme = params['scheme']
  tempFolder = "/Volumes/Macintosh\ HD/Users/pavelyankelevich/Tmp/Previews/#{scheme}"
  FileUtils::mkdir_p '"' + tempFolder + '"' 

  cmd = "xcodebuild -sdk iphonesimulator9.0 -workspace '/Volumes/Macintosh\ HD/Users/pavelyankelevich/Work/Rashim/Rashim.xcworkspace' -scheme '#{scheme}' -configuration Release -derivedDataPath '#{tempFolder}'"
#  puts system cmd

  result = $?.to_i
#  puts result

  if result==0 then
    tempFolder += '/Build/Products/Release-iphonesimulator'

    cmd = "cd '#{tempFolder}' && zip -r -X '#{scheme}.zip' '#{scheme}.app'"
    puts cmd
    puts system cmd

    postData = Net::HTTP.post_form(URI.parse('https://api.appetize.io/v1/app/update'), { "token" => "tok_p5451b2aep2cpzjnj1rdt647pg", "url" => "http://www.example.com/my_app.zip", "platform" => "ios" })

    puts postData.body
  else
    puts 'Build failed'
    500
  end
end

get '/clean/:scheme' do
  scheme = params['scheme']
  output = `xcodebuild  -workspace '/Volumes/Macintosh\ HD/Users/pavelyankelevich/Work/Rashim/Rashim.xcworkspace' -scheme '#{scheme}' clean`
  puts output
end

get '/schemes' do
  schemesPattern = "Schemes:"
  output = `xcodebuild -workspace '/Volumes/Macintosh\ HD/Users/pavelyankelevich/Work/Rashim/Rashim.xcworkspace' -list`
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