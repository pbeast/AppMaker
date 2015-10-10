#!/usr/bin/env ruby


=begin
	
xcodebuild -workspace PublishingTestApp.xcworkspace -scheme PublishingTestApp PROFILE=af367fcf-16b5-49c3-9c28-e3d563d7abf9 SIGNING='iPhone Distribution: Mobitti Ltd. (P2WQ65BAA8)' -derivedDataPath '~/Tmp/Previews/PublishingTestApp' -archivePath '~/Tmp/Previews/PublishingTestApp' archive
xcodebuild -exportArchive -archivePath ~/Tmp/Previews/PublishingTestApp.xcarchive -exportPath ~/Tmp/Previews/PublishingTestApp -exportOptionsPlist ~/Work/AppMaker/exportPList.plist

=


require 'fastlane_core'
require 'spaceship'
require 'colorize'

=begin
package_path = FastlaneCore::IpaUploadPackageBuilder.new.generate(
        app_id: '1034264437',
        ipa_path: '/Users/pavelyankelevich/Tmp/Previews/PublishingTestApp/PublishingTestApp.ipa',
        package_path: "/Users/pavelyankelevich/Tmp"
      )

puts package_path.yellow

transporter = FastlaneCore::ItunesTransporter::new('ypavel@outlook.com', '!111Zzzz')
transporter.upload('1034264437', package_path)

#puts transporter.download('1034264437')
=end

Spaceship::Tunes.login('ypavel@outlook.com', '!111Zzzz')
app = Spaceship::Tunes::Application.find(1034264437)

version = app.edit_version

builds = version.candidate_builds
builds.each do |build|
   puts build
   puts '---------------------'
end

#version.select_build(builds.first)
#version.save!

puts 'Done'

