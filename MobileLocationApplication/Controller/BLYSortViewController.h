//
//  BLYSortViewController.h
//  MobileLocationApplication
//
//  Created by Sana Hassan on 3/2/14.
//  Copyright (c) 2014 Belly. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BLYSortViewDelegate <NSObject>
-(void)sortButtonSelected:(NSNumber *)sortValue;
@end

@interface BLYSortViewController : UIViewController
@property (nonatomic, weak) id<BLYSortViewDelegate> filterDelegate;
@property (nonatomic, strong) NSString *labelText;
@property (nonatomic, assign) NSUInteger sortSelected;
@end
