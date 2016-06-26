#!/usr/bin/env ruby

$LOAD_PATH << '.'

require 'spaceship'
require 'openssl'
require 'fileutils'

require 'config'

PROFILES_LOCATION = File::expand_path("~/Library/MobileDevice/Provisioning\ Profiles")

def camel_case(str)
  words = str.downcase.split
  words.shift + words.map(&:capitalize).join
end

if ARGV[0].nil?
  puts 'Please provide bundle id prefix'
  exit
end

 if ARGV[2].nil?
   puts 'Please provide device id'
   exit
 end

 if ARGV[1].nil?
   puts 'Please provide device name'
   exit
 end

client = Spaceship.login(AppMakerConfig::DEV_USER, AppMakerConfig::DEV_PASSWORD)
puts "Logged in"
#Spaceship.select_team

client.team_id = 'P2WQ65BAA8'
#puts "Team Selected: #{client.team_information.name}"

#Spaceship.app.all.collect do |app|
#  puts app
#end

#FileUtils::mkdir_p appName

app = Spaceship.app.find(ARGV[0])
if !app.nil?
  puts 'Application Found:'
  puts app.app_id
  puts app.name
  puts app.bundle_id

  devices = Spaceship::Device.all

  devProfiles = Spaceship.provisioning_profile.development.find_by_bundle_id(ARGV[0])
  devProfile = devProfiles.first
  puts "Profile uuid: #{devProfile.uuid}"

  puts 'Removing old profile'
  cmd = `rm '#{PROFILES_LOCATION}/#{devProfile.uuid}.mobileprovision'`

  puts 'Creating New Device'
  newDevice = Spaceship.device.create!(name: ARGV[1], udid: ARGV[2])
  devProfile.devices = Spaceship.device.all

  puts 'Updating provide'
  devProfile.update!

  puts "Installing new Profile"
  devProfiles = Spaceship.provisioning_profile.development.find_by_bundle_id(ARGV[0])
  devProfile = devProfiles.first
  profileFileName = "#{PROFILES_LOCATION}/#{devProfile.uuid}.mobileprovision"
  File.write(profileFileName, devProfile.download)
  puts "Profile stored at #{profileFileName}"

  exit
end

puts "Application '#{ARGV[0]}' not found."
