#!/usr/bin/env ruby

$LOAD_PATH << '.'

require 'spaceship'
require 'openssl'

require 'config'

client = Spaceship.login(AppMakerConfig::DEV_USER, AppMakerConfig::DEV_PASSWORD)
puts "Logged in"

client.team_id = 'P2WQ65BAA8'

excludeString = "Achva, Ariel, Ariel Teachers, Around Me, Around Me Supplier, Beit Berl, Beit Berl Teachers, Betsalel, David Yellin, Efrata, Fastlane Test App, Gordon, Haifa, Haifa Staff, Israel College, Kineret, Levinsky App, Mobitti Academic"

excludeList = excludeString.split(', ')

Spaceship.app.all.collect do |app|
 	puts 'Application found:'
 	puts app.app_id
 	puts app.name
 	puts app.bundle_id
 	puts ''

 	if excludeList.include?(app.name)
 		puts "Skipping"
	 	puts '--------------------------------------------'
 		puts ''
 	else
	 	basePath = File.join("PushCertificates", app.name)

	 	FileUtils::mkdir_p basePath

	 	appNameJoined = app.name.split(' ').join

	 	# Create a new certificate signing request
	 	prod_csr, prod_pkey = Spaceship.certificate.create_certificate_signing_request

	 	# Use the signing request to create a new push certificate
	 	prodCert = Spaceship.certificate.production_push.create!(csr: prod_csr, bundle_id: app.bundle_id)

	 	prod_pfx = OpenSSL::PKCS12.create('Abcd1234', app.bundle_id, prod_pkey, prodCert.download)

	 	fileName = File.join(basePath, appNameJoined + '_Production_Push.p12')

	 	File.open(fileName, 'w') {
	 	  |f| f.write(prod_pfx.to_der)
	 	}

	 	puts 'Production push certificate stored to ' + fileName

	 	# Create a new certificate signing request
	 	dev_csr, dev_pkey = Spaceship.certificate.create_certificate_signing_request

	 	# Use the signing request to create a new push certificate
	 	devCert = Spaceship.certificate.development_push.create!(csr: dev_csr, bundle_id: app.bundle_id)

	 	dev_pfx = OpenSSL::PKCS12.create('Abcd1234', app.bundle_id, dev_pkey, devCert.download)

	 	fileName = File.join(basePath, appNameJoined + '_Development_Push.p12')
	 	File.open(fileName, 'w') {
	 	  |f| f.write(dev_pfx.to_der)
	 	}
	 	puts 'Development push certificate stored to ' + fileName

	 	puts '--------------------------------------------'
	 	puts ''
	 end
end

