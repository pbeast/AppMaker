#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

$LOAD_PATH << '.'

require 'spaceship'
require 'colorize'

require 'config'
require 'parse-ruby-client'

def StoreAppInParse(app, parse)
  application = parse.object("Application")
  application["Name"] = app.name
  application["apple_id"] = app.apple_id
  application["bundle_id"] = app.bundle_id
  application["app_icon_preview_url"] = app.app_icon_preview_url

  details = app.details
  application["primary_category"] = details.primary_category[details.primary_category.index('.')+1..-1]
  application["secondary_category"] = details.secondary_category[details.secondary_category.index('.')+1..-1]

  live_version = app.live_version
  #puts live_version

  # puts app
  # puts "------------------------------------------------------------------------------------------------------------".red

  # puts details
  # puts "------------------------------------------------------------------------------------------------------------".red
  #
  # puts app.live_version
  # puts "------------------------------------------------------------------------------------------------------------".red


  application["version"] = live_version.version
	application["review_first_name"] = live_version.review_first_name
	application["review_last_name"] = live_version.review_last_name
	application["review_phone_number"] = live_version.review_phone_number
	application["review_email"] = live_version.review_email
	application["review_demo_user"] = live_version.review_demo_user
  application["review_demo_password"] = live_version.review_demo_password
  application["review_notes"] = live_version.review_notes
  application["description"] = live_version.description["en-US"]
  application["keywords"] = live_version.keywords["en-US"]
  application["large_app_icon"] = live_version.large_app_icon.url
  application["supportURL"] = live_version.support_url["en-US"]

  application.save
end


parse = Parse.create :application_id => "svGqYa9l2DYSLduyvo1ICgRwwHzhhSCEVUIGDnLi", # required
                     :api_key => "lCERmFJuKa8dwdJbVYC7hu0Vx4lwQFJSdjtieQFv", # required
                     :quiet => true # optional, defaults to false

Spaceship::Tunes.login(AppMakerConfig::USER, AppMakerConfig::PASSWORD)
puts 'Logged In'.green


apps = Spaceship::Tunes::Application.all

 # app= apps.last
 #
 # puts StoreAppInParse(app, parse)
 #
 # exit


apps.each do |app|
  if (app.live_version.nil?)
#		puts "Still not published. Application status: #{app.edit_version.app_status}".green
#		puts app.edit_version
  else
    puts "#{app.name} Published. Version in store: #{app.live_version.version}".green
    StoreAppInParse(app, parse)
  end
end

#puts app.
#puts app.

#apps.each do |app|
#	puts app.name
#end
