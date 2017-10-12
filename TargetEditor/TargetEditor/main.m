//
//  main.m
//  NewTarget
//
//  Created by Pavel Yankelevich on 1/31/16.
//  Copyright © 2016 Pavel Yankelevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TargetEditor.h"
#import <GBCli/GBCli.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        __block BOOL printHelp = NO;
        
        GBOptionsHelper *options = [[GBOptionsHelper alloc] init];
        [options registerOption:'p' long:@"project" description:@"Project to add or configure target" flags:GBOptionRequiredValue];
        [options registerOption:'t' long:@"target" description:@"Target name to add or configure" flags:GBOptionRequiredValue];
        [options registerOption:'a' long:@"base-target" description:@"Target name to use as a template" flags:GBOptionRequiredValue];
        [options registerOption:'e' long:@"edit" description:@"Edit target insted of creating a new one" flags:GBOptionNoValue];
        [options registerOption:0 long:@"provision-dev" description:@"Development provisioning profile" flags:GBOptionOptionalValue];
        [options registerOption:0 long:@"provision-prod" description:@"Production provisioning profile" flags:GBOptionOptionalValue];
        [options registerOption:0 long:@"code-sign-dev" description:@"Development code signing identity" flags:GBOptionOptionalValue];
        [options registerOption:0 long:@"code-sign-prod" description:@"Production code signing identity" flags:GBOptionOptionalValue];
        [options registerOption:0 long:@"automatic-profiles" description:@"Try to find provisioning profiles automatically" flags:GBOptionNoValue];
        //[options registerOption:'v' long:@"version-up" description:@"Raise version" flags:GBOptionNoValue];
        [options registerOption:'b' long:@"bundle-id" description:@"Bundle identifier" flags:GBOptionOptionalValue];
        [options registerOption:'h' long:@"help" description:@"Prints help" flags:GBOptionNoValue];

        GBCommandLineParser *parser = [[GBCommandLineParser alloc] init];
        [parser registerOption:@"project" shortcut:'p' requirement:GBValueRequired];
        [parser registerOption:@"target" shortcut:'t' requirement:GBValueRequired];
        [parser registerOption:@"base-target" shortcut:'a' requirement:GBValueRequired];
        [parser registerOption:@"provision-dev" shortcut:0 requirement:GBValueOptional];
        [parser registerOption:@"provision-prod" shortcut:0 requirement:GBValueOptional];
        [parser registerOption:@"code-sign-dev" shortcut:0 requirement:GBValueOptional];
        [parser registerOption:@"code-sign-prod" shortcut:0 requirement:GBValueOptional];
        [parser registerOption:@"automatic-profiles" shortcut:0 requirement:GBValueNone];
        //[parser registerOption:@"version-up" shortcut:'v' requirement:GBValueNone];
        [parser registerOption:@"bundle-id" shortcut:'b' requirement:GBValueOptional];

        [parser registerOption:@"edit" shortcut:'e' requirement:GBValueNone];
        [parser registerOption:@"help" shortcut:'h' requirement:GBValueNone];
        
        GBSettings *settings = [GBSettings settingsWithName:@"CmdLine" parent:nil];
        
        // Parse command line
        [parser parseOptionsWithArguments:(char **)argv count:argc block:^(GBParseFlags flags, NSString *option, id value, BOOL *stop) {
            switch (flags) {
                case GBParseFlagUnknownOption:
                    printf("Unknown command line option %s, try --help!\n", [option UTF8String]);
                    break;
                case GBParseFlagMissingValue:
                    printf("Missing value for command line option %s, try --help!\n", [option UTF8String]);
                    break;
                case GBParseFlagOption:
                    if ([option isEqualToString:@"help"])
                        printHelp = YES;
                    
                    [settings setObject:value forKey:option];
                    break;
                case GBParseFlagArgument:
                    [settings addArgument:value];
                    break;
            }
        }];

        NSString* project = [parser valueForOption:@"project"];
        NSString* target = [parser valueForOption:@"target"];
        NSNumber* isEdit = [parser valueForOption:@"edit"];

        
//        NSLog(@"Code Sign Dev: %@", [settings objectForKey:@"code-sign-dev"]);
//        NSLog(@"Code Sign Prod: %@", [settings objectForKey:@"code-sign-prod"]);
//        NSLog(@"Prov. Profile Dev: %@", [settings objectForKey:@"provision-dev"]);
//        NSLog(@"Prov. Profile Prod: %@", [settings objectForKey:@"provision-prod"]);
//        NSLog(@"Bundle Id: %@", [settings objectForKey:@"bundle-id"]);
//        
//        return 0;
        
        if (printHelp || project == nil || target == nil) {
            [options printHelp];
            return 0;
        }

        TargetEditor * maker = [[TargetEditor alloc] initWithSettings:settings];
        if (isEdit == nil || [isEdit boolValue] == NO)
            [maker createNewTarget];
        else
            [maker editTarget];
    }
    
    return 0;
}
