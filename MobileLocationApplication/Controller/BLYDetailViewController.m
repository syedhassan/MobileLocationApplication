//
//  BLYDetailViewController.m
//  MobileLocationApplication
//
//  Created by Sana Hassan on 3/2/14.
//  Copyright (c) 2014 Belly. All rights reserved.
//

#import "BLYDetailViewController.h"
#import "OAServiceTicket.h"
#import <MapKit/MapKit.h>
#import "BLYSingletonManager.h"

@interface BLYDetailViewController ()
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIImageView *businessImage;
@property (strong, nonatomic) IBOutlet UILabel *businessName;
@property (strong, nonatomic) IBOutlet UILabel *phoneLabel;
@property (strong, nonatomic) IBOutlet UILabel *closedOpenLabel;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *categoryLabel;
@property (strong, nonatomic) IBOutlet UIImageView *reviewImage;
@property (strong, nonatomic) IBOutlet UILabel *address1Label;
@property (strong, nonatomic) IBOutlet UILabel *address2Label;
@property (strong, nonatomic) IBOutlet UIImageView *snippetImage;
@property (strong, nonatomic) IBOutlet UILabel *snippetTextLabel;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) BLYSingletonManager *globalCache;
@end

@implementation BLYDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.globalCache = [BLYSingletonManager singletonInstance];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.activityIndicator startAnimating];
    self.activityIndicator.center = self.containerView.center;
    self.containerView.hidden = YES;
    [self downloadDataForApi:[NSString stringWithFormat:@"business/%@", self.businessId] withLimit:nil  andParams:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)requestDidFinishWithData:(OAServiceTicket *)ticket {
    NSString *response= [[NSString alloc] initWithData:ticket.data encoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&err];
    
    [self.activityIndicator stopAnimating];
    NSLog(@"Reseponse = \n%@", response);
    if ([json objectForKey:@"error"]) {//What is this error?
        NSString *msg = [[json objectForKey:@"error"] objectForKey:@"description"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: [[json objectForKey:@"error"] objectForKey:@"text"] message:msg delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if ([json objectForKey:@"name"])
        self.businessName.text = [json objectForKey:@"name"];
    
    if ([json objectForKey:@"display_phone"]) {
        self.phoneLabel.text = [json objectForKey:@"display_phone"];
    }
    
    BOOL isClosed = [[json objectForKey:@"is_closed"] boolValue];
    if (!isClosed) {
        self.closedOpenLabel.textColor = [UIColor greenColor];
        self.closedOpenLabel.text = @"Open";
    }
    
    if (self.distanceString)
        self.distanceLabel.text = self.distanceString;
    
    NSArray *categories = [json objectForKey:@"categories"];
    NSMutableString *cat = [[NSMutableString alloc] initWithCapacity:40];
    for (int i=0;i< [categories count];i=i+2) {
        NSArray *s =[categories objectAtIndex:i];
        [cat appendString:[s firstObject]];
        [cat appendString:@"/"];
    }
    self.categoryLabel.text = [cat substringToIndex:[cat length]-1];
    
    if ([json objectForKey:@"rating_img_url_small"]) {
        UIImage *img = [self.globalCache.reviewImageCache objectForKey:[json objectForKey:@"rating_img_url_small"]];
        if (img) {
            self.reviewImage.image = img;
        } else {
            
        }
    }
    [self.activityIndicator stopAnimating];
    self.activityIndicator.center = self.containerView.center;
    self.containerView.hidden = NO;
    
}

- (void)requestDidFailWithError:(OAServiceTicket *)ticket {
    NSLog(@"ERROR!!!! %@",ticket);
}

@end
