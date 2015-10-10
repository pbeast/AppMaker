#!/usr/bin/env ruby

$LOAD_PATH << '.'

require 'spaceship'

require 'config'

if ARGV[0].nil?
  puts 'Please provide Application Bundle Id'
  exit
end

app_id = ARGV[0]

client = Spaceship.login(AppMakerConfig::DEV_USER, AppMakerConfig::DEV_PASSWORD)

puts "Logged in"

client.team_id = 'P2WQ65BAA8'

app = Spaceship.app.find(app_id)
if !app.nil?
  puts "Application found: #{app.name} - #{app.app_id} - #{app.bundle_id}"

  app.delete!
  puts 'Application deleted'
end

puts 'Checking Production Provisioning Profiles For ' + app_id
productionProfiles = Spaceship.provisioning_profile.app_store.find_by_bundle_id(app_id)
productionProfiles.each do |profile|
    name = profile.name
    profile.delete!
    puts name + ' deleted'
end

puts 'Checking Development Provisioning Profiles For ' + app_id
developmentProfiles = Spaceship.provisioning_profile.development.find_by_bundle_id(app_id)
developmentProfiles.each do |profile|
  name = profile.name
  profile.delete!
  puts name + ' deleted'
end