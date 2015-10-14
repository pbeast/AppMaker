#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

$LOAD_PATH << '.'

require 'spaceship'
require 'colorize'

require 'config'
require 'parse-ruby-client'

parse = Parse.create :application_id => "svGqYa9l2DYSLduyvo1ICgRwwHzhhSCEVUIGDnLi", # required
             :api_key        => "lCERmFJuKa8dwdJbVYC7hu0Vx4lwQFJSdjtieQFv", # required
             :quiet          => false  # optional, defaults to false

Spaceship::Tunes.login(AppMakerConfig::USER, AppMakerConfig::PASSWORD)
puts 'Logged In'.green


apps = Spaceship::Tunes::Application.all
#app = apps.last

=begin
application = parse.object("Application")
application["Name"] = app.name
application["apple_id"] = app.apple_id
application["bundle_id"] = app.bundle_id
application["app_icon_preview_url"] = app.app_icon_preview_url
application["version"] = app.live_version.version

details = app.details
application["primary_category"] = details.primary_category
application["secondary_category"] = details.secondary_category

puts details

result = application.save
puts result

=end
	
apps.each do |app|
	if (app.live_version.nil?)
#		puts "Still not published. Application status: #{app.edit_version.app_status}".green
#		puts app.edit_version
	else
		puts "Published. Version in store: #{app.live_version.version}".green
		application = parse.object("Application")
		application["Name"] = app.name
		application["apple_id"] = app.apple_id
		application["bundle_id"] = app.bundle_id
		application["app_icon_preview_url"] = app.app_icon_preview_url
		application["version"] = app.live_version.version

		details = app.details
		application["primary_category"] = details.primary_category
		application["secondary_category"] = details.secondary_category

		result = application.save
	end
end

#puts app.
#puts app.

#apps.each do |app|
#	puts app.name
#end
