//
//  BLYTableViewCell.h
//  MobileLocationApplication
//
//  Created by Sana Hassan on 2/27/14.
//  Copyright (c) 2014 Belly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLYTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *businessName;
@property (strong, nonatomic) IBOutlet UILabel *businessDistance;
@property (strong, nonatomic) IBOutlet UILabel *businessType;
@property (strong, nonatomic) IBOutlet UILabel *businessStatus;
@property (strong, nonatomic) IBOutlet UIImageView *reviewStarImageView;

@end
