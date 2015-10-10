#!/usr/bin/env ruby

$LOAD_PATH << '.'

require 'spaceship'
require 'openssl'

require 'config'

def camel_case(str)
  words = str.downcase.split
  words.shift + words.map(&:capitalize).join
end

if ARGV[0].nil?
  puts 'Please provide Application Name to create'
  exit
end

if ARGV[1].nil?
  puts 'Please provide bundle id prefix'
  exit
end

appName = ARGV[0]
appNameJoined = ARGV[0].split(' ').join
app_id = ARGV[1] + '.' + camel_case(appName)

client = Spaceship.login(AppMakerConfig::DEV_USER, AppMakerConfig::DEV_PASSWORD)
puts "Logged in"
#Spaceship.select_team

client.team_id = 'P2WQ65BAA8'
#puts "Team Selected: #{client.team_information.name}"

#Spaceship.app.all.collect do |app|
#  puts app
#end

app = Spaceship.app.find(app_id)
if !app.nil?
  puts 'Application already exists:'
  puts app.app_id
  puts app.name
  puts app.bundle_id

  devices = Spaceship::Device.all

devCerts = Spaceship.certificate.development.all
puts 'got devCerts'

profile = Spaceship.provisioning_profile.development.create!(bundle_id: app_id, certificate: devCerts, name: appName + ' Development')
File.write(appName + ' Development.mobileprovision', profile.download)
puts "Development provisioning profile created: #{profile.name}"

  exit
end

puts "Application '#{app_id}' not found. Will create one..."

app = Spaceship.app.create!(bundle_id: app_id, name: appName)
puts "App created: #{app.app_id}"

# Create a new certificate signing request
prod_csr, prod_pkey = Spaceship.certificate.create_certificate_signing_request

# Use the signing request to create a new push certificate
prodCert = Spaceship.certificate.production_push.create!(csr: prod_csr, bundle_id: app_id)

prod_pfx = OpenSSL::PKCS12.create('Abcd1234', app_id, prod_pkey, prodCert.download)

File.open(appNameJoined + '_Production_Push.p12', 'w') {
  |f| f.write(prod_pfx.to_der)
}

puts 'Production push certificate stored to ' + appNameJoined + '_Production_Push.p12'

# Create a new certificate signing request
dev_csr, dev_pkey = Spaceship.certificate.create_certificate_signing_request

# Use the signing request to create a new push certificate
devCert = Spaceship.certificate.development_push.create!(csr: dev_csr, bundle_id: app_id)

dev_pfx = OpenSSL::PKCS12.create('Abcd1234', app_id, dev_pkey, devCert.download)

File.open(appNameJoined + '_Development_Push.p12', 'w') {
  |f| f.write(dev_pfx.to_der)
}

puts 'Development push certificate stored to ' + appNameJoined + '_Development_Push.p12'

devCerts = Spaceship.certificate.development.all
profile = Spaceship.provisioning_profile.development.create!(bundle_id: app_id, certificate: devCerts, name: appName + ' Development')
File.write(appName + ' Development.mobileprovision', profile.download)
puts "Development provisioning profile created: #{profile.name}"

prodCert = Spaceship.certificate.production.all.first
productionProfile = Spaceship.provisioning_profile.app_store.create!(bundle_id: app_id, certificate: prodCert, name: appName + ' Production')
File.write(appName + ' Production.mobileprovision', productionProfile.download)
puts "Production provisioning profile created: #{productionProfile.name}"
