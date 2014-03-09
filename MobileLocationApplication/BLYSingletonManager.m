//
//  BLYSingletonManager.m
//  MobileLocationApplication
//
//  Created by Sana Hassan on 3/2/14.
//  Copyright (c) 2014 Belly. All rights reserved.
//

#import "BLYSingletonManager.h"

@implementation BLYSingletonManager

+ (id)singletonInstance {
    static BLYSingletonManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return  manager;
}

- (id)init {
    if (self = [super init]) {
        self.imageCache = [[NSMutableDictionary alloc] initWithCapacity:40];
        self.reviewImageCache = [[NSMutableDictionary alloc] initWithCapacity:5];
    }
    return self;
}

@end
