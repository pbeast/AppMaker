#!/usr/bin/env ruby

$LOAD_PATH << '.'

require 'spaceship'
require 'colorize'

require 'config'

Spaceship::Tunes.login(AppMakerConfig::USER, AppMakerConfig::PASSWORD)
puts 'Logged In'.green


appName = 'Test SpaceShip App'
bundleId = 'PY.testSpaceshipApp'
appDescription = 'Super Application, created using automation scripts!!!'

app = Spaceship::Tunes::Application.find(bundleId)
if app.nil?
  puts 'App not found. Will Create a new one'.green

  app = Spaceship::Tunes::Application.create!(name: appName,
                                              primary_language: 'English',
                                              version: '1.0',
                                              sku: bundleId,
                                              bundle_id: bundleId)

    puts 'App Created'.green
else
  puts "Application found: #{app.name}".green

  if (app.live_version.nil?)
    puts "Still not published. Application status: #{app.edit_version.app_status}".green
  else
    puts "Published. Version in store: #{app.live_version.version}".green
#    puts app.live_version
  end

  #puts "#{app.name} v#{app.edit_version.version} status: #{@app.edit_version.app_status}".yellow
end

app.update_price_tier!(0)

details = app.details
details.name['en-US'] = appName
details.privacy_url['en-US'] = "http://mobitti.com/term_of_use_mobitti.htm"
details.primary_category = "Education"
details.secondary_category = "Lifestyle"

details.save!
puts 'Application details updated'.green

v = app.edit_version

v.copyright = "#{Time.now.year} Mobitti Ltd."
v.support_url['en-US'] = 'http://www.jamd.ac.il/'
v.description['en-US'] = appDescription
v.keywords['en-US'] = "a, b, c"

v.save!
puts 'Application updated'.green

v.update_rating({
  'UNRESTRICTED_WEB_ACCESS' => 0,
  'GAMBLING_CONTESTS' => 0,
  'CARTOON_FANTASY_VIOLENCE' => 1,
  'REALISTIC_VIOLENCE' => 0,
  'PROLONGED_GRAPHIC_SADISTIC_REALISTIC_VIOLENCE' => 0,
  'PROFANITY_CRUDE_HUMOR' => 1,
  'MATURE_SUGGESTIVE' => 1,
  'HORROR' => 0,
  'MEDICAL_TREATMENT_INFO' => 0,
  'ALCOHOL_TOBACCO_DRUGS' => 1,
  'GAMBLING' => 0,
  'SEXUAL_CONTENT_NUDITY' => 0,
  'GRAPHIC_SEXUAL_CONTENT_NUDITY' => 0
})

v.save!
puts 'Application rating updated'.green

v.review_first_name = 'Eyal'
v.review_last_name = 'Koren'
v.review_phone_number = '+972544926535'
v.review_email = 'pavel@yankel.me'
v.review_demo_user = '034725721'
v.review_demo_password = '519'
v.review_notes = ''

v.save!
puts 'Application reviewer information updated'.green

v.upload_screenshot!('/Users/pbeast/Work/PublishingTestApp/screenshots/en-US/en-US-iPhone4-0-LandingScreen-portrait.png', 1, 'en-US', 'iphone35')
v.upload_screenshot!('/Users/pbeast/Work/PublishingTestApp/screenshots/en-US/en-US-iPhone5-0-LandingScreen-portrait.png', 1, 'en-US', 'iphone4')
v.upload_screenshot!('/Users/pbeast/Work/PublishingTestApp/screenshots/en-US/en-US-iPhone6-0-LandingScreen-portrait.png', 1, 'en-US', 'iphone6')
v.upload_screenshot!('/Users/pbeast/Work/PublishingTestApp/screenshots/en-US/en-US-iPhone6Plus-0-LandingScreen-portrait.png', 1, 'en-US', 'iphone6Plus')
v.save!
puts 'Screenshots updated'.green

v.upload_large_icon!('/Users/pbeast/Work/PublishingTestApp/screenshots/LargeAppIcon.png')
v.save!
puts 'Large icon updated'.green


submission = app.create_submission

# Set app submission information
submission.content_rights_contains_third_party_content = false
submission.content_rights_has_rights = true
submission.add_id_info_uses_idfa = false

# Finalize app submission
submission.complete!

puts 'Application submission completed'.green


