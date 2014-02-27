//
//  BLYTableViewCell.m
//  MobileLocationApplication
//
//  Created by Sana Hassan on 2/27/14.
//  Copyright (c) 2014 Belly. All rights reserved.
//

#import "BLYTableViewCell.h"

@implementation BLYTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat imageSize = 70;
    CGFloat yPos = (self.frame.size.height - imageSize)/2.0;
    self.imageView.frame = CGRectMake(5, yPos,imageSize,imageSize);
    self.businessName.frame = CGRectMake(self.imageView.frame.origin.x + self.imageView.frame.size.width + 5, self.businessName.frame.origin.y, self.businessName.frame.size.width, self.businessName.frame.size.height);
    self.businessDistance.frame = CGRectMake(self.imageView.frame.origin.x + self.imageView.frame.size.width + 5, self.businessDistance.frame.origin.y, self.businessDistance.frame.size.width, self.businessDistance.frame.size.height);
    self.businessType.frame = CGRectMake(self.imageView.frame.origin.x + self.imageView.frame.size.width + 5, self.businessType.frame.origin.y, self.businessType.frame.size.width, self.businessType.frame.size.height);
}

@end
