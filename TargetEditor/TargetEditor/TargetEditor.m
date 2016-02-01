//
//  NewTargetMaker.m
//  NewTarget
//
//  Created by Pavel Yankelevich on 1/31/16.
//  Copyright © 2016 Pavel Yankelevich. All rights reserved.
//

#import "TargetEditor.h"
#import "XcodeEditor.h"

@interface TargetEditor()
{
    GBSettings* _settings;
}

@end

@implementation TargetEditor

-(instancetype)initWithSettings:(GBSettings*)settings{
    self = [super init];
    if (self) {
        self->_settings = settings;
    }
    return self;
}

-(void)editTarget{
    
}

-(void)createNewTarget{
    NSString* projFile = [self resolvePath:[_settings objectForKey:@"project"]];
    NSString* newTargetName = [_settings objectForKey:@"target"];
    
    XCProject* project = [[XCProject alloc] initWithFilePath:projFile];
        
//    for (XCTarget* target in [project targets]) {
//        NSLog(@"%@", [target name]);
//        XCProjectBuildConfig* config = [target configurationWithName:@"Debug"];
//        
//        NSLog(@"%@", [config valueForKey:@"PROVISIONING_PROFILE"]);
//        NSLog(@"%@", [config valueForKey:@"CODE_SIGN_IDENTITY"]);
//    }
    
    XCTarget* target = [project targetWithName:@"publishingTestApp"];
    
    XCTarget* duplicatedTarget = [target duplicateWithTargetName:newTargetName productName:newTargetName];
    [duplicatedTarget setProductName:newTargetName];
    XCProjectBuildConfig* debugTargetConfig = [duplicatedTarget configurationWithName:@"Debug"];
    XCProjectBuildConfig* releaseTargetConfig = [duplicatedTarget configurationWithName:@"Release"];
    
//    NSLog(@"%@", [duplicatedTargetConfig valueForKey:@"PROVISIONING_PROFILE"]);
//    NSLog(@"%@", [duplicatedTargetConfig valueForKey:@"CODE_SIGN_IDENTITY"]);
//    NSLog(@"%@", [duplicatedTargetConfig valueForKey:@"INFOPLIST_FILE"]);
//    NSLog(@"%@", [duplicatedTargetConfig valueForKey:@"PROJECT_NAME"]);
//    NSLog(@"%@", [duplicatedTargetConfig valueForKey:@"PRODUCT_BUNDLE_IDENTIFIER"]);
    
    NSString* baseInfoFileName = (NSString*)[debugTargetConfig valueForKey:@"INFOPLIST_FILE"];
    baseInfoFileName = [baseInfoFileName lastPathComponent];

    NSString* rootProjectPath = [projFile stringByDeletingPathExtension];

    NSError* error;
    
    NSString* newTargetFilesPath = [[rootProjectPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newTargetName];
    [[NSFileManager defaultManager] createDirectoryAtPath:newTargetFilesPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSString* groupPath = newTargetName;
    
    NSString* infoFile = [NSString stringWithContentsOfFile:[rootProjectPath stringByAppendingPathComponent:baseInfoFileName] encoding:NSUTF8StringEncoding error:&error ];
    NSString* infoFileName = [newTargetName stringByAppendingString:@".plist"];
    XCSourceFileDefinition *infoFileDefinition = [XCSourceFileDefinition sourceDefinitionWithName:infoFileName text:infoFile type:PropertyList];
    
    XCGroup *newGroup = [[project rootGroup] addGroupWithPath:groupPath];
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


/*
 int pid = [[NSProcessInfo processInfo] processIdentifier];
 NSPipe *pipe = [NSPipe pipe];
 NSFileHandle *file = pipe.fileHandleForReading;
 
 NSTask *task = [[NSTask alloc] init];
 task.launchPath = @"/usr/bin/grep";
 task.arguments = @[@"foo", @"bar.txt"];
 task.standardOutput = pipe;
 
 [task launch];
 
 NSData *data = [file readDataToEndOfFile];
 [file closeFile];
 
 NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
 NSLog (@"grep returned:\n%@", grepOutput);
 */
@end