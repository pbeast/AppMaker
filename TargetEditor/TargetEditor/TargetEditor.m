//
//  NewTargetMaker.m
//  NewTarget
//
//  Created by Pavel Yankelevich on 1/31/16.
//  Copyright © 2016 Pavel Yankelevich. All rights reserved.
//

#import "TargetEditor.h"
#import "XcodeEditor.h"
#import "ProvisioningProfileBean.h"

#define kDefaultProfilesPath @"/Library/MobileDevice/Provisioning Profiles"

@interface TargetEditor()
{
    GBSettings* _settings;
    NSArray* extensions;
    NSMutableArray* profiles;
}

@end

@implementation TargetEditor

-(instancetype)initWithSettings:(GBSettings*)settings{
    self = [super init];
    if (self) {
        self->_settings = settings;
        self->extensions = @[@"mobileprovision", @"provisionprofile"];
    }
    return self;
}

- (void)loadLocalProfiles
{
    profiles = [NSMutableArray array];
    
    NSString* profilesPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), kDefaultProfilesPath];
    
    // searching for the profiles
    NSArray *provisioningProfiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:profilesPath error:nil];
    provisioningProfiles = [provisioningProfiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension IN %@", extensions]];
    for (NSString *path in provisioningProfiles)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", profilesPath, path] isDirectory:NO]) {
            ProvisioningProfileBean *profile = [[ProvisioningProfileBean alloc] initWithPath:[NSString stringWithFormat:@"%@/%@", profilesPath, path]];
            [profiles addObject:profile];
        }
    }
}

-(void)editTarget{
    NSString* projFile = [self resolvePath:[_settings objectForKey:@"project"]];
    NSString* targetName = [_settings objectForKey:@"target"];
    
    XCProject* project = [[XCProject alloc] initWithFilePath:projFile];
    
//    NSString* rootProjectPath = [projFile stringByDeletingPathExtension];
    
    XCTarget* target = [project targetWithName:targetName];
    if (target == nil){
        NSLog(@"Target %@ not found in project", targetName);
        return;
    }

    XCProjectBuildConfig* debugTargetConfig = [target configurationWithName:@"Debug"];
    XCProjectBuildConfig* releaseTargetConfig = [target configurationWithName:@"Release"];

    if ([_settings objectForKey:@"code-sign-dev"]!= nil)
        [debugTargetConfig addOrReplaceSetting:[_settings objectForKey:@"code-sign-dev"] forKey:@"CODE_SIGN_IDENTITY"];
    
    if ([_settings objectForKey:@"code-sign-prod"]!= nil)
        [releaseTargetConfig addOrReplaceSetting:[_settings objectForKey:@"code-sign-prod"] forKey:@"CODE_SIGN_IDENTITY"];
    
    if ([_settings boolForKey:@"automatic-profiles"]){
        [self loadLocalProfiles];
        NSString* bundleId = (NSString*)[debugTargetConfig valueForKey:@"PRODUCT_BUNDLE_IDENTIFIER"];
        NSArray<ProvisioningProfileBean*>* debugAppProfiles = [profiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bundleIdentifier == %@ and debug == 'YES' and valid == 'YES'", bundleId]];
        NSArray<ProvisioningProfileBean*>* releaseAppProfiles = [profiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bundleIdentifier == %@ and debug == 'NO' and valid == 'YES'", bundleId]];
        
        if ([debugAppProfiles count] > 0){
            [debugTargetConfig addOrReplaceSetting:[debugAppProfiles[0] UUID] forKey:@"PROVISIONING_PROFILE"];
//            [debugTargetConfig addOrReplaceSetting:[debugAppProfiles[0] UUID] forKey:@"PROVISIONING_PROFILE[sdk=iphoneos*]"];
        }
        
        if ([releaseAppProfiles count] > 0){
            [releaseTargetConfig addOrReplaceSetting:[releaseAppProfiles[0] UUID] forKey:@"PROVISIONING_PROFILE"];
//            [releaseTargetConfig addOrReplaceSetting:[releaseAppProfiles[0] UUID] forKey:@"PROVISIONING_PROFILE[sdk=iphoneos*]"];
        }
    }
    else{
        if ([_settings objectForKey:@"provision-dev"]!= nil){
            [debugTargetConfig addOrReplaceSetting:[_settings objectForKey:@"provision-dev"] forKey:@"PROVISIONING_PROFILE"];
//            [debugTargetConfig addOrReplaceSetting:[_settings objectForKey:@"provision-dev"] forKey:@"PROVISIONING_PROFILE[sdk=iphoneos*]"];
        }
        if ([_settings objectForKey:@"provision-prod"]!= nil){
            [releaseTargetConfig addOrReplaceSetting:[_settings objectForKey:@"provision-prod"] forKey:@"PROVISIONING_PROFILE"];
//            [releaseTargetConfig addOrReplaceSetting:[_settings objectForKey:@"provision-prod"] forKey:@"PROVISIONING_PROFILE[sdk=iphoneos*]"];
        }
    }
        
    [project save];
}

-(void)createNewTarget{
    NSString* projFile = [self resolvePath:[_settings objectForKey:@"project"]];
    NSString* newTargetName = [_settings objectForKey:@"target"];
    
    XCProject* project = [[XCProject alloc] initWithFilePath:projFile];
    
    NSString* rootProjectPath = [projFile stringByDeletingPathExtension];
    NSString* projectName = [rootProjectPath lastPathComponent];

    XCTarget* target = [project targetWithName:projectName];
    
    XCTarget* duplicatedTarget = [target duplicateWithTargetName:newTargetName productName:newTargetName];

    XCProjectBuildConfig* debugTargetConfig = [duplicatedTarget configurationWithName:@"Debug"];
    XCProjectBuildConfig* releaseTargetConfig = [duplicatedTarget configurationWithName:@"Release"];
    
    NSString* baseInfoFileName = (NSString*)[debugTargetConfig valueForKey:@"INFOPLIST_FILE"];
    baseInfoFileName = [baseInfoFileName lastPathComponent];

    NSError* error;
    
    NSString* newTargetFilesPath = [[rootProjectPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newTargetName];
    [[NSFileManager defaultManager] createDirectoryAtPath:newTargetFilesPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSString* groupPath = newTargetName;
    
    NSString* infoFile = [NSString stringWithContentsOfFile:[rootProjectPath stringByAppendingPathComponent:baseInfoFileName] encoding:NSUTF8StringEncoding error:&error ];
    
    /*
    NSString* entitelmentsTemplateFileName = [rootProjectPath stringByAppendingPathComponent:@"$template$.entitlements"];
    NSString* entitelmentsFileSource = [NSString stringWithContentsOfFile:entitelmentsTemplateFileName encoding:NSUTF8StringEncoding error:&error];
    NSString* entitelmentsFileName = [newTargetName stringByAppendingString:@".entitlements"];
    XCSourceFileDefinition *entitelmentsFileDefinition = [XCSourceFileDefinition sourceDefinitionWithName:entitelmentsFileName text:entitelmentsFileSource type:PropertyList];
    
    NSString *entitelmentsFileKey = [[XCKeyBuilder forItemNamed:entitelmentsFileName] build];
    XCSourceFile *entitelmentsSourceFile = [XCSourceFile sourceFileWithProject:project key:entitelmentsFileKey type:PropertyList name:entitelmentsFileName sourceTree:@"/" path:[newTargetFilesPath stringByAppendingPathComponent:entitelmentsFileName]];
    NSLog(@"%@", [entitelmentsSourceFile description]);
*/
    
    XCGroup *newGroup = [[project rootGroup] addGroupWithPath:groupPath];
    
    NSString* infoFileName = [newTargetName stringByAppendingString:@".plist"];
    XCSourceFileDefinition *infoFileDefinition = [XCSourceFileDefinition sourceDefinitionWithName:infoFileName text:infoFile type:PropertyList];
    
    [newGroup addSourceFile:infoFileDefinition];
    
    NSString* infoRelativePath = [[@"$(SRCROOT)" stringByAppendingPathComponent:newTargetName] stringByAppendingPathComponent:infoFileName];
    [debugTargetConfig addOrReplaceSetting:infoRelativePath forKey:@"INFOPLIST_FILE"];
    [releaseTargetConfig addOrReplaceSetting:infoRelativePath forKey:@"INFOPLIST_FILE"];

    if ([_settings objectForKey:@"bundle-id"] != nil){
        [debugTargetConfig addOrReplaceSetting:[_settings objectForKey:@"bundle-id"] forKey:@"PRODUCT_BUNDLE_IDENTIFIER"];
        [releaseTargetConfig addOrReplaceSetting:[_settings objectForKey:@"bundle-id"] forKey:@"PRODUCT_BUNDLE_IDENTIFIER"];
    }
    
    if ([_settings objectForKey:@"code-sign-dev"]!= nil)
        [debugTargetConfig addOrReplaceSetting:[_settings objectForKey:@"code-sign-dev"] forKey:@"CODE_SIGN_IDENTITY"];
    if ([_settings objectForKey:@"code-sign-prod"]!= nil)
        [releaseTargetConfig addOrReplaceSetting:[_settings objectForKey:@"code-sign-prod"] forKey:@"CODE_SIGN_IDENTITY"];
    
    if ([_settings objectForKey:@"provision-dev"]!= nil)
        [debugTargetConfig addOrReplaceSetting:[_settings objectForKey:@"provision-dev"] forKey:@"PROVISIONING_PROFILE"];
    if ([_settings objectForKey:@"provision-prod"]!= nil)
        [releaseTargetConfig addOrReplaceSetting:[_settings objectForKey:@"provision-prod"] forKey:@"PROVISIONING_PROFILE"];
    
    [project save];
    
    NSString* podFileName = [[rootProjectPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Podfile"];
    error = nil;
    NSString* podFile = [NSString stringWithContentsOfFile:podFileName encoding:NSUTF8StringEncoding error:&error];
    if (error == nil){
        podFile = [podFile stringByAppendingString:[NSString stringWithFormat:@"\n\ntarget '%@' do\nend", newTargetName]];
        [podFile writeToFile:podFileName atomically:NO encoding:NSUTF8StringEncoding error:&error];
    }
}

- (NSString *)resolvePath:(NSString *)path {
    NSString *expandedPath = [[path stringByExpandingTildeInPath] stringByStandardizingPath];
    const char *cpath = [expandedPath cStringUsingEncoding:NSUTF8StringEncoding];
    char *resolved = NULL;
    char *returnValue = realpath(cpath, resolved);
    
    if (returnValue == NULL && resolved != NULL) {
        printf("Error with path: %s\n", resolved);
        // if there is an error then resolved is set with the path which caused the issue
        // returning nil will prevent further action on this path
        return nil;
    }
    
    return [NSString stringWithCString:returnValue encoding:NSUTF8StringEncoding];
}

@end