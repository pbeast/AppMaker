#!/usr/bin/env ruby

$LOAD_PATH << '.'

require 'spaceship'
require 'colorize'

require 'config'

Spaceship::Tunes.login(AppMakerConfig::USER, AppMakerConfig::PASSWORD)
puts 'Logged In'.green


apps = Spaceship::Tunes::Application.all
app = apps.last
puts app.apple_id
puts app.name
puts app.bundle_id
if (app.live_version.nil?)
	puts "Still not published. Application status: #{app.edit_version.app_status}".green
	puts app.edit_version
else
	puts "Published. Version in store: #{app.live_version.version}".green
	#puts app.live_version
	details = app.details
	puts details.name['en-US']
	puts details.privacy_url['en-US']
	puts details.primary_category
	puts details.secondary_category
end

#puts app.
#puts app.

#apps.each do |app|
#	puts app.name
#end
