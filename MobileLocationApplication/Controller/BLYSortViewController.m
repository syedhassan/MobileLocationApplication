//
//  BLYSortViewController.m
//  MobileLocationApplication
//
//  Created by Sana Hassan on 3/2/14.
//  Copyright (c) 2014 Belly. All rights reserved.
//

#import "BLYSortViewController.h"

@interface BLYSortViewController()
@property (strong, nonatomic) IBOutlet UILabel *noOfBusiness;
@property (strong, nonatomic) IBOutlet UIButton *bestMatchedButton;
@property (strong, nonatomic) IBOutlet UIButton *distanceButton;
@property (strong, nonatomic) IBOutlet UIButton *highestRatedButton;
@end

@implementation BLYSortViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.noOfBusiness.text = self.labelText;
    UIColor *selectedColor = [UIColor colorWithRed:223.0/255.0 green:237.0/255.0 blue:255.0/255.0 alpha:1];
    switch (self.sortSelected) {
        case 0:
            [self.bestMatchedButton setBackgroundColor:selectedColor];
            break;
        case 1:
            [self.distanceButton setBackgroundColor:selectedColor];
            break;
        case 2:
            [self.highestRatedButton setBackgroundColor:selectedColor];
            break;
        default:
            [self.bestMatchedButton setBackgroundColor:selectedColor];
            break;
    }
}
- (IBAction)bestMatchedSelected:(id)sender {
    id<BLYSortViewDelegate> fd = self.filterDelegate;
    if ([fd respondsToSelector:@selector(sortButtonSelected:)]) {
        [fd performSelector:@selector(sortButtonSelected:) withObject:[NSNumber numberWithInt:0]];
    }
}

- (IBAction)distanceButtonSelected:(id)sender {
    id<BLYSortViewDelegate> fd = self.filterDelegate;
    if ([fd respondsToSelector:@selector(sortButtonSelected:)]) {
        [fd performSelector:@selector(sortButtonSelected:) withObject:[NSNumber numberWithInt:1]];
    }
}

- (IBAction)highestRatedButtonSelected:(id)sender {
    id<BLYSortViewDelegate> fd = self.filterDelegate;
    if ([fd respondsToSelector:@selector(sortButtonSelected:)]) {
        [fd performSelector:@selector(sortButtonSelected:) withObject:[NSNumber numberWithInt:2]];
    }
}

@end