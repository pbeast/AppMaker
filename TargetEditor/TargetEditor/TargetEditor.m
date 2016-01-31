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
    NSArray* arguments;
}

@end

@implementation TargetEditor

- (instancetype)initWithArgs:(NSArray*)args{
    self = [super init];
    if (self) {
        self->arguments = args;
    }
    return self;
}

-(void)createNewTarget:(NSString*)newTargetName forProject:(NSString*)projectPath{
    NSString* projFile = [self resolvePath:projectPath];
    
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
    [duplicatedTarget setScriptingProperties:@{}];
    XCProjectBuildConfig* duplicatedTargetConfig = [duplicatedTarget configurationWithName:@"Debug"];
    
//    NSLog(@"%@", [duplicatedTargetConfig valueForKey:@"PROVISIONING_PROFILE"]);
//    NSLog(@"%@", [duplicatedTargetConfig valueForKey:@"CODE_SIGN_IDENTITY"]);
//    NSLog(@"%@", [duplicatedTargetConfig valueForKey:@"INFOPLIST_FILE"]);
//    NSLog(@"%@", [duplicatedTargetConfig valueForKey:@"PROJECT_NAME"]);
//    NSLog(@"%@", [duplicatedTargetConfig valueForKey:@"PRODUCT_BUNDLE_IDENTIFIER"]);
    
    NSString* baseInfoFileName = (NSString*)[duplicatedTargetConfig valueForKey:@"INFOPLIST_FILE"];
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
//    NSLog(@"New %@", [newGroup description]);
    
    NSString* infoRelativePath = [[@"$(SRCROOT)" stringByAppendingPathComponent:newTargetName] stringByAppendingPathComponent:infoFileName];
    [duplicatedTargetConfig addOrReplaceSetting:infoRelativePath forKey:@"INFOPLIST_FILE"];

    NSString *bundleId = [NSString stringWithFormat:@"py.apps.%@", [[newTargetName capitalizedString] stringByReplacingOccurrencesOfString:@" " withString:@""]];
    
    [duplicatedTargetConfig addOrReplaceSetting:bundleId forKey:@"PRODUCT_BUNDLE_IDENTIFIER"];
    
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