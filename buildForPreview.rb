#!/usr/bin/env ruby



#cmd = "xcodebuild -sdk iphonesimulator9.0 -workspace './PublishingTestApp.xcworkspace' -scheme 'PublishingTestApp' -configuration Release -derivedDataPath ./ > /dev/null 2>&1"
#cmd = "xcodebuild -sdk iphonesimulator9.0 -workspace './PublishingTestApp.xcworkspace' -scheme 'PublishingTestApp' -configuration Release -derivedDataPath ./"
#cmd = "xcodebuild -sdk iphonesimulator9.0 -workspace '/Volumes/Macintosh\ HD/Users/pavelyankelevich/Work/Junk/PublishingTestApp/PublishingTestApp.xcworkspace' -scheme 'PublishingTestApp' -configuration Release -derivedDataPath '/Volumes/Macintosh\ HD/Users/pavelyankelevich/Tmp'"

# xcodebuild -workspace './PublishingTestApp.xcworkspace' -scheme 'PublishingTestApp' -archivePath builds/publishingTestApp.xcarchive archive
# xcodebuild -exportArchive -archivePath builds/publishingTestApp.xcarchive -exportPath builds/publishingTestApp.ipa

#puts system cmd


#puts $?
#value = %x[#{cmd}]

#puts value ? "true" : "false"

require 'fastlane_core'
require 'colorize'

package_path = FastlaneCore::IpaUploadPackageBuilder.new.generate(
        app_id: '1034264437',
        ipa_path: '/Users/pavelyankelevich/Tmp/Previews/PublishingTestApp/PublishingTestApp.ipa',
        package_path: "/Users/pavelyankelevich/Tmp"
      )

puts package_path.yellow

transporter = FastlaneCore::ItunesTransporter::new('ypavel@outlook.com', '!111Zzzz')
transporter.upload('1034264437', package_path)

puts transporter.download('1034264437')
puts 'Done'

