//
//  NewTargetMaker.h
//  NewTarget
//
//  Created by Pavel Yankelevich on 1/31/16.
//  Copyright © 2016 Pavel Yankelevich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TargetEditor : NSObject

-(instancetype)initWithArgs:(NSArray*)args;

-(void)createNewTarget:(NSString*)newTargetName forProject:(NSString*)projectPath;

@end
