//
//  BLYTableViewController.m
//  MobileLocationApplication
//
//  Created by Sana Hassan on 2/25/14.
//  Copyright (c) 2014 Belly. All rights reserved.
//

#import "BLYTableViewController.h"
#import "OAuthConsumer.h"
#import "BLYTableViewCell.h"
#import <CoreLocation/CoreLocation.h>

@interface BLYTableViewController () <CLLocationManagerDelegate>
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (assign, nonatomic) NSUInteger totalResults;
@property (strong, atomic) NSCache *imageCache;
@property (strong, atomic) NSCache *reviewStartImageCache;
@property (strong, nonatomic) NSMutableArray *businesses;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic) double latitude, longitude;
@end

@implementation BLYTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.businesses = [[NSMutableArray alloc] initWithCapacity:100];
        self.imageCache = [[NSCache alloc] init];
        self.reviewStartImageCache = [[NSCache alloc] init];
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
}

- (void) setup {
    self.tableView.hidden = YES;
    self.activityIndicator.transform = CGAffineTransformMakeScale(2.0f, 2.0f);
    UILabel *locations = [[UILabel alloc] init];
    locations.text = @"Locations";
    locations.textColor = [UIColor whiteColor];
    CGSize size = [locations.text sizeWithAttributes:@{NSFontAttributeName:locations.font}];
    locations.bounds = CGRectMake(0, 0, size.width, size.height);
    self.navigationItem.titleView = locations;
}

- (void) downloadData {
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AppConfig" ofType:@"plist"]];
    
    OAConsumer *consumer = [[OAConsumer alloc] initWithKey:[dictionary objectForKey:@"ConsumerKey"] secret:[dictionary objectForKey:@"ConsumerSecret"]];
    OAToken *token = [[OAToken alloc] initWithKey:[dictionary objectForKey:@"Token"] secret:[dictionary objectForKey:@"TokenSecret"]];
    NSURL *searchURL = [NSURL URLWithString:@"http://api.yelp.com/v2/search"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:searchURL
                                                                   consumer:consumer
                                                                      token:token
                                                                      realm:nil
                                                          signatureProvider:nil];
    [request setHTTPMethod:@"GET"];
    
    NSString *latLongString = [NSString stringWithFormat:@"%f,%f", self.latitude, self.longitude];
    OARequestParameter * qParam1 = [[OARequestParameter alloc] initWithName:@"ll" value:latLongString];
    OARequestParameter * qParam2 = [[OARequestParameter alloc] initWithName:@"sort" value:@"1"];
    OARequestParameter * qParam4 = [[OARequestParameter alloc] initWithName:@"limit" value:@"10"];
    OARequestParameter * qParam3 = [[OARequestParameter alloc] initWithName:@"offset" value:[NSString stringWithFormat:@"%d", [self.businesses count]]];
    [request setParameters:[NSArray arrayWithObjects:qParam1,qParam2,qParam3,qParam4,nil]];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestDidFinishWithData:)
                  didFailSelector:@selector(requestDidFailWithError:)];
}

- (void)requestDidFinishWithData:(OAServiceTicket *)ticket {
    NSString *response= [[NSString alloc] initWithData:ticket.data encoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&err];

    //NSLog(@"Response  %@", response);
    if ([json objectForKey:@"error"]) {//What is the error?
        NSString *msg = [[json objectForKey:@"error"] objectForKey:@"description"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: [[json objectForKey:@"error"] objectForKey:@"text"] message:msg delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [self.activityIndicator stopAnimating];
        return;
    }
    
    self.totalResults = [[json objectForKey:@"total"] integerValue];
    NSArray *bsn = [json objectForKey:@"businesses"];
    [self.businesses addObjectsFromArray:bsn];
    
    //self.pageNumber = [NSNumber numberWithInt:[self.pageNumber integerValue] + 1];
    [self.tableView reloadData];
    
    self.tableView.hidden = NO;
    self.backgroundView.hidden = NO;
    self.backgroundView.backgroundColor = [UIColor whiteColor];
    [self.activityIndicator stopAnimating];
}

- (void)requestDidFailWithError:(OAServiceTicket *)ticket {
    NSLog(@"ERROR!!!! %@",ticket);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.businesses count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"BLYTableViewCell";
    BLYTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil];
        cell = [nib objectAtIndex:0];
        cell.imageView.layer.cornerRadius = 2;
        cell.imageView.clipsToBounds = YES;
    }
    cell.imageView.image = nil; cell.reviewStarImageView.image = nil;
    
    cell.businessName.text = [[self.businesses objectAtIndex:indexPath.row] objectForKey:@"name"];
    
    cell.businessType.text = @"";
    NSArray *categories = [[self.businesses objectAtIndex:indexPath.row] objectForKey:@"categories"];
    if (categories) {//For simplicity let's take the first category.
        NSArray *firstCategory = [categories firstObject];
        if (firstCategory) {
            cell.businessType.text = [firstCategory firstObject];
        }
    }
    
    NSNumber *distance = [[self.businesses objectAtIndex:indexPath.row] objectForKey:@"distance"];
    if (distance) {
        CGFloat distanceInMts = [distance floatValue];
        cell.businessDistance.text = [NSString stringWithFormat:@"%.2f miles away", (distanceInMts/1069)];
    }
    
    BOOL isClosed = [[[self.businesses objectAtIndex:indexPath.row] objectForKey:@"is_closed"] boolValue];
    if (isClosed) {
        cell.businessStatus.text = @"Closed";
        cell.businessStatus.textColor = [UIColor lightGrayColor];
    } else {
        cell.businessStatus.text = @"Open";
        cell.businessStatus.textColor = [UIColor colorWithRed:64.0/255.0 green:142.0/255.0 blue:35.0/255.0 alpha:1.0];
    }
    
    NSString *imageURL = [[self.businesses objectAtIndex:indexPath.row] objectForKey:@"image_url"];
    if (imageURL) {
        [self applyImageFromURl:imageURL toImageView:cell.imageView fromCache:self.imageCache forIndexPath:indexPath];
    } else {
        //Do default image for the business.
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"png"];
        UIImage *testImage = [UIImage imageWithContentsOfFile:filePath];
        cell.imageView.image = testImage;
    }
    
    NSString *reviewImageURL = [[self.businesses objectAtIndex:indexPath.row] objectForKey:@"rating_img_url_small"];
    if (reviewImageURL) {
        [self applyImageFromURl:reviewImageURL toImageView:cell.reviewStarImageView fromCache:self.reviewStartImageCache forIndexPath:indexPath];
    }
    
    return cell;
}

- (void) applyImageFromURl:(NSString *)imageURL toImageView:(UIImageView *)imageView fromCache:(NSCache *)cache forIndexPath:(NSIndexPath *)indexPath {
    UIImage *image = [cache objectForKey:imageURL];
    if (image) {
        imageView.image = image;
    } else {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        dispatch_async(queue, ^(void) {
            NSIndexPath *cellIndex = indexPath;
            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
            UIImage *img = [[UIImage alloc] initWithData:imageData];
            if (img) {
                [cache setObject:img forKey:imageURL];

                dispatch_async(dispatch_get_main_queue(), ^{
                    BLYTableViewCell *c = (BLYTableViewCell *)[self.tableView cellForRowAtIndexPath:cellIndex];
                    if ([[self.tableView visibleCells] containsObject:c]) {
                        if (c) {
                            imageView.image = img;
                            [c setNeedsLayout];
                        }
                    }
                });
            }
        });
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == [self.businesses count] - 3 && [self.businesses count] < self.totalResults) {
        [self.activityIndicator startAnimating];
        [self downloadData];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    if (location) {
        self.latitude = location.coordinate.latitude;
        self.longitude = location.coordinate.longitude;
        [self.locationManager stopUpdatingLocation];
        [self downloadData];
    }
}

@end
