#!/usr/bin/env ruby

require 'spaceship'
require 'openssl'

if ARGV[0].nil?
  puts 'Please provide bundle id'
  exit
end

app_id = ARGV[0]

client = Spaceship.login('ypavel@gmail.com', 'Dk&9t6W6yWL7')
puts "Logged in"
#Spaceship.select_team

client.team_id = 'P2WQ65BAA8'

app = Spaceship.app.find(app_id)
if app.nil?
  puts 'Application not found'

  exit
end

puts 'Application found:'
puts app.app_id
puts app.name
puts app.bundle_id

appNameJoined = app.name.split(' ').join

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
