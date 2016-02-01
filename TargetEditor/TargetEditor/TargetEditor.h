//
//  NewTargetMaker.h
//  NewTarget
//
//  Created by Pavel Yankelevich on 1/31/16.
//  Copyright © 2016 Pavel Yankelevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GBCli/GBCli.h>

@interface TargetEditor : NSObject

-(instancetype)initWithSettings:(GBSettings*)settings;

-(void)createNewTarget;
-(void)editTarget;

@end
