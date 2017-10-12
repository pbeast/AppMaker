#!/usr/bin/env ruby

$LOAD_PATH << '.'

require 'spaceship'
require 'openssl'
require 'colorize'
require 'config'

client = Spaceship.login(AppMakerConfig::DEV_USER, AppMakerConfig::DEV_PASSWORD)
puts "Logged in as #{AppMakerConfig::DEV_USER}"
#Spaceship.select_team

client.team_id = 'P2WQ65BAA8'

prod_push_certs = Spaceship::Portal.certificate.production_push.all
dev_push_certs = Spaceship::Portal.certificate.development_push.all

apps = Spaceship.app.all.collect
apps.each { |app|
  app_dev_certs = dev_push_certs.find_all { |c| c.owner_name == app.bundle_id}
  app_prod_certs = prod_push_certs.find_all { |c| c.owner_name == app.bundle_id}

  next if app_dev_certs.length == 0 and app_prod_certs.length == 0

  puts "#{app.name} - #{app.bundle_id}. Existing Certificates:".white
  
  if app_dev_certs.length > 0
    puts "\tDevelopment:".white
    app_dev_certs.each { |c|
      puts "\t\t#{c.id}: Created: #{c.created}; Expires: #{c.expires}".yellow
    }
  end

  if app_prod_certs.length > 0
    puts "\tProduction:".white
    app_prod_certs.each { |c|
      puts "\t\t#{c.id}: Created: #{c.created}; Expires: #{c.expires}".yellow
    }
  end

  puts "\tDeleting Existing Certificates...".red
  app_dev_certs.each { |c| c.revoke! }
  puts "\t\tDevelopment Certificates Deleted".red
  app_prod_certs.each { |c| c.revoke! } 
  puts "\t\tProduction Certificates Deleted".red
  
  puts "\tCreating New Certificates...".green

  appNameJoined = app.name.split(' ').join
  
  # Create a new certificate signing request
  prod_csr, prod_pkey = Spaceship.certificate.create_certificate_signing_request
  
  # Use the signing request to create a new push certificate
  prodCert = Spaceship.certificate.production_push.create!(csr: prod_csr, bundle_id: app.bundle_id)
  
  prod_pfx = OpenSSL::PKCS12.create('Abcd1234', app.bundle_id, prod_pkey, prodCert.download)
  
  newCertificateFileName = "New Certificates/" + app.name + '/' + appNameJoined + '_Production_Push.p12'
  FileUtils.mkdir_p(File.dirname(newCertificateFileName))

  File.open(newCertificateFileName, 'w') {
    |f| f.write(prod_pfx.to_der)
  }
  
  puts "\t\tProduction push certificate stored to #{newCertificateFileName}".green
  
  # Create a new certificate signing request
  dev_csr, dev_pkey = Spaceship.certificate.create_certificate_signing_request
  
  # Use the signing request to create a new push certificate
  devCert = Spaceship.certificate.development_push.create!(csr: dev_csr, bundle_id: app.bundle_id)
  
  dev_pfx = OpenSSL::PKCS12.create('Abcd1234', app.bundle_id, dev_pkey, devCert.download)
  
  newCertificateFileName = "New Certificates/" + app.name + '/' + appNameJoined + '_Development_Push.p12'
  FileUtils.mkdir_p(File.dirname(newCertificateFileName))

  File.open(newCertificateFileName, 'w') {
    |f| f.write(dev_pfx.to_der)
  }
  puts "\t\tDevelopment push certificate stored to to #{newCertificateFileName}".green
}
