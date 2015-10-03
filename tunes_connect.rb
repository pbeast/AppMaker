require 'spaceship'
require 'deliver'

class TunesConnect
  def initialize(bundleId)
    @bundleId = bundleId

    Spaceship::Tunes.login('mobitti', 'Mobitti2014')
    puts 'Logged In'
  end

  def getApp
    @app = Spaceship::Tunes::Application.find(@bundleId)
    if !@app.nil?
      puts "#{@app.name} v#{@app.live_version.version} status: #{@app.live_version.app_status}"
    else
      puts 'App not found'
    end

    !@app.nil?
  end

  def createApp(name)
    @app = Spaceship::Tunes::Application.create!(name: name,
                                                primary_language: 'English',
                                                version: '1.0', # initial version
                                                sku: @bundleId,
                                                bundle_id: @bundleId)

    puts 'App Created'
  end

  def updateApp(appDescription)
    v = @app.live_version

    v.copyright = "#{Time.now.year} Mobitti Ltd."
    v.description['English'] = appDescription

    v.primary_category = 'Education'
    v.secondary_category = 'Lifestyle'

    v.review_first_name = 'Eyal'
    v.review_last_name = 'Koren'
    v.review_phone_number = '+972544926535'
    v.review_email = 'pavel@yankel.me'
    v.review_demo_user = '034725721'
    v.review_demo_password = '519'
    v.review_notes = ''

    v.privacy_url['English'] = 'http://mobitti.com/term_of_use_mobitti.htm'
    v.support_url['English'] = 'http://www.jamd.ac.il/'

    v.keywords['English'] = 'האקדמיה למוסיקה ולמחול בירושלים, ירושלים, אקדמיה למוסיקה ומחול, מכלול, jamd, מידע אישי, אקדמיה למוסיקה ולמחול,  Jerusalem Academy of Music and Dance, ראשים.'

    v.save!

    puts 'App updated'
  end

  def ListAllApps
    Spaceship::Tunes::Application.all.collect do |app|
      puts "#{app.name} v#{app.live_version.version} status: #{app.live_version.app_status}"
    end
  end
end

if __FILE__ == $0

#  app = Deliver::App.new(app_identifier: '1034264437')
#  exit


  tunesConnect = TunesConnect.new('mobitti.rashim.musicAcademy')
  gotApp = tunesConnect.getApp
  if gotApp
    puts 'App Found!!! Will update...'
    tunesConnect.updateApp('אקדמיה למוסיקה ולמחול בירושלים')
  else
    puts 'Going to create new app...'
    tunesConnect.createApp('אקדמיה למוסיקה ולמחול בירושלים')
    tunesConnect.getApp
  end
end