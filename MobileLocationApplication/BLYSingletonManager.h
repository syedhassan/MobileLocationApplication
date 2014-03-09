//
//  BLYSingletonManager.h
//  MobileLocationApplication
//
//  Created by Sana Hassan on 3/2/14.
//  Copyright (c) 2014 Belly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLYSingletonManager : NSObject

@property (nonatomic, retain) NSMutableDictionary *imageCache;
@property (nonatomic, retain) NSMutableDictionary *reviewImageCache;

+ (id)singletonInstance;

@end
