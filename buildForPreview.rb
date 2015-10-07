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


uploader = FastlaneCore::ItunesTransporter::new('ypavel@gmail.com', 'Dk&9t6W6yWL7')
puts uploader.download('1034264437')
puts 'Done'

