//
//  BLYBaseViewController.h
//  MobileLocationApplication
//
//  Created by Sana Hassan on 3/2/14.
//  Copyright (c) 2014 Belly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLYBaseViewController : UIViewController
- (void)downloadDataForApi:(NSString *)api withLimit:(NSString *)limit andParams:(NSDictionary*)params;
@end
