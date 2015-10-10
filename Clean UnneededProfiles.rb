#!/usr/bin/env ruby

$LOAD_PATH << '.'

require 'spaceship'
require 'config'


client = Spaceship.login(AppMakerConfig::DEV_USER, AppMakerConfig::DEV_PASSWORD)
puts "Logged in"
client.team_id = 'P2WQ65BAA8'

# Select all 'Invalid' or 'Expired' provisioning profiles
broken_profiles = Spaceship.provisioning_profile.all.find_all do |profile| 
  # the below could be replaced with `!profile.valid?`, which takes longer but also verifies the code signing identity
  (profile.status == "Invalid" or profile.status == "Expired") 
end

# Iterate over all broken profiles and repair them
broken_profiles.each do |profile|
  profile.repair! # yes, that's all you need to repair a profile
  puts profile.name + 'repaired!	'
end