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
        [options registerOption:'b' long:@"target" description:@"Target name to add or configure" flags:GBOptionRequiredValue];
        [options registerOption:'e' long:@"edit" description:@"Edit target insted of creating a new one" flags:GBOptionNoValue];
        [options registerOption:'h' long:@"help" description:@"Prints help" flags:GBOptionNoValue];

        GBCommandLineParser *parser = [[GBCommandLineParser alloc] init];
        [parser registerOption:@"project" shortcut:'p' requirement:GBValueRequired];
        [parser registerOption:@"target" shortcut:'t' requirement:GBValueRequired];
        [parser registerOption:@"edit" shortcut:'e' requirement:GBValueNone];
        [parser registerOption:@"help" shortcut:'h' requirement:GBValueNone];
        
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
                    // do something with 'option' and its 'value'
                    break;
                case GBParseFlagArgument:
                    // do something with argument 'value'
                    break;
            }
        }];

        NSString* project = [parser valueForOption:@"project"];
        NSString* target = [parser valueForOption:@"target"];
        NSNumber* isEdit = [parser valueForOption:@"edit"];

        if (printHelp || project == nil || target == nil) {
            [options printHelp];
            return 0;
        }

        TargetEditor * maker = [[TargetEditor alloc] init];
        if (isEdit == nil || [isEdit boolValue] == NO)
            [maker createNewTarget:target forProject:project];
    }
    
    return 0;
}
