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
#import <MapKit/MapKit.h>
#import "BLYSortViewController.h"
#import "BLYSingletonManager.h"
#import "BLYDetailViewController.h"

#define METERS_PER_MILE 1609.344

@interface BLYTableViewController () <CLLocationManagerDelegate, MKMapViewDelegate, BLYSortViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIToolbar *toolBar;
@property (strong, nonatomic) IBOutlet UILabel *sortLabel;
@property (strong, nonatomic) IBOutlet UILabel *mapLabel;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (assign, nonatomic) NSUInteger totalResults;
@property (strong, nonatomic) NSMutableArray *businesses;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic) double latitude, longitude;
@property (strong, nonatomic) NSMutableArray *locationsArray;
@property (assign, nonatomic) NSUInteger sortValue;
@property (strong, nonatomic) BLYSingletonManager *globalCache;
@end


@implementation BLYTableViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.businesses = [[NSMutableArray alloc] initWithCapacity:40];
        self.locationsArray = [[NSMutableArray alloc] initWithCapacity:40];
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    self.sortValue = 0;
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, -self.mapView.frame.size.height, self.mapView.frame.size.width, self.mapView.frame.size.height)];
    self.mapView.delegate = self;
}

- (void) setup {
    
    self.activityIndicator.transform = CGAffineTransformMakeScale(2.0f, 2.0f);
    
    UILabel *locations = [[UILabel alloc] init];
    locations.text = @"Locations";
    locations.textColor = [UIColor whiteColor];
    locations.font = [UIFont boldSystemFontOfSize:18];
    CGSize size = [locations.text sizeWithAttributes:@{NSFontAttributeName:locations.font}];
    locations.bounds = CGRectMake(0, 0, size.width, size.height);
    self.navigationItem.titleView = locations;
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.toolBar.frame.size.height, 0);
    self.tableView.hidden = YES;
    
    self.mapLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapLabelTapped)];
    [self.mapLabel addGestureRecognizer:tapGesture1];
    
    self.sortLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sortLabelTapped)];
    [self.sortLabel addGestureRecognizer:tapGesture2];
    
    self.globalCache = [BLYSingletonManager singletonInstance];
}

- (void) setupMapWithLocation:(CLLocationCoordinate2D)currentLocation {
    MKCoordinateRegion rgon = MKCoordinateRegionMakeWithDistance(currentLocation, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    MKCoordinateRegion region = MKCoordinateRegionMake(currentLocation, rgon.span);
    [self.mapView setRegion:region];
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:currentLocation];
    [annotation setTitle:@"Current Location"];
    [self.locationsArray addObject:annotation];
}

- (void) downloadDataForApi:(NSString *)api withLimit:(NSString *)limit {
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AppConfig" ofType:@"plist"]];
    
    OAConsumer *consumer = [[OAConsumer alloc] initWithKey:[dictionary objectForKey:@"ConsumerKey"] secret:[dictionary objectForKey:@"ConsumerSecret"]];
    OAToken *token = [[OAToken alloc] initWithKey:[dictionary objectForKey:@"Token"] secret:[dictionary objectForKey:@"TokenSecret"]];
    NSURL *searchURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.yelp.com/v2/%@", api]];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:searchURL
                                                                   consumer:consumer
                                                                      token:token
                                                                      realm:nil
                                                          signatureProvider:nil];
    [request setHTTPMethod:@"GET"];
    if ([api isEqualToString:@"search"]) {
        NSString *latLongString = [NSString stringWithFormat:@"%f,%f", self.latitude, self.longitude];
        OARequestParameter * qParam1 = [[OARequestParameter alloc] initWithName:@"ll" value:latLongString];
        OARequestParameter * qParam2 = [[OARequestParameter alloc] initWithName:@"sort" value:[NSString stringWithFormat:@"%d", self.sortValue]];
        if (!limit) limit = @"10";
        OARequestParameter * qParam4 = [[OARequestParameter alloc] initWithName:@"limit" value:limit];
        OARequestParameter * qParam3 = [[OARequestParameter alloc] initWithName:@"offset" value:[NSString stringWithFormat:@"%d", [self.businesses count]]];
        [request setParameters:[NSArray arrayWithObjects:qParam1,qParam2,qParam3,qParam4,nil]];
    }
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestDidFinishWithData:)
                  didFailSelector:nil];
}

- (void)requestDidFinishWithData:(OAServiceTicket *)ticket {
    NSString *response= [[NSString alloc] initWithData:ticket.data encoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&err];
    
    if ([json objectForKey:@"error"]) {//What is this error?
       
        NSString *msg = [[json objectForKey:@"error"] objectForKey:@"description"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: [[json objectForKey:@"error"] objectForKey:@"text"] message:msg delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [self.activityIndicator stopAnimating];
        return;
    }
    
    self.totalResults = [[json objectForKey:@"total"] integerValue];
    NSArray *bsn = [json objectForKey:@"businesses"];
    [self.businesses addObjectsFromArray:bsn];
    
    [self.tableView reloadData];
    
    self.tableView.hidden = NO;
    self.backgroundView.hidden = NO;
    self.backgroundView.backgroundColor = [UIColor whiteColor];
    [self.activityIndicator stopAnimating];
    [self fetchGeoCodesForBusiness:self.businesses];
}

- (void)mapLabelTapped {
    if (self.mapView.superview != self.view) {
        self.sortLabel.hidden = YES;
        [UIView animateWithDuration:0.3
                              delay:0.1
                            options: UIViewAnimationOptionTransitionCurlUp
                         animations:^ {
                             self.mapView.frame = CGRectMake(0, 0, self.mapView.frame.size.width, self.mapView.frame.size.height);
                             self.tableView.frame = CGRectMake(0, 500, self.tableView.frame.size.width, self.tableView.frame.size.height);
                         }
                         completion:^(BOOL finished)  {
                             self.tableView.hidden = YES;
                             [self.mapView addAnnotations:self.locationsArray];
                             
                         }];
        [self.view addSubview:self.mapView];
        [self.mapLabel setText:@"List"];
    }
    else {
        self.tableView.hidden = NO;
        self.sortLabel.hidden = NO;
        [UIView animateWithDuration:0.3
                              delay:0.1
                            options: UIViewAnimationOptionTransitionCurlDown
                         animations:^{
                             self.mapView.frame = CGRectMake(0, -self.mapView.frame.size.height, self.mapView.frame.size.width, self.mapView.frame.size.height);
                             self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height);
                         }
                         completion:^(BOOL finished){
                             [self.mapView removeFromSuperview];
                             [self.mapView removeAnnotations:self.mapView.annotations];
                             
                         }];
        [self.mapLabel setText:@"Map"];
    }
}

- (void)sortLabelTapped {
    BLYSortViewController *c = [[BLYSortViewController alloc] init];
    c.labelText = [NSString stringWithFormat:@"Filtering %d businesses", [self.businesses count]];
    c.sortSelected = self.sortValue;
    c.filterDelegate = self;
    [self presentViewController:c animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.businesses count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *business = [self.businesses objectAtIndex:indexPath.row];
    BLYDetailViewController *details = [[BLYDetailViewController alloc] initWithNibName:NSStringFromClass([BLYDetailViewController class]) bundle:nil];
    details.businessId = [business objectForKey:@"id"];
    NSNumber *distance = [[self.businesses objectAtIndex:indexPath.row] objectForKey:@"distance"];
    if (distance) {
        CGFloat distanceInMts = [distance floatValue];
        details.distanceString = [NSString stringWithFormat:@"%.2f miles away", (distanceInMts/1069)];
    }
    [self.navigationController pushViewController:details animated:YES];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
        [self applyImageFromURl:imageURL toImageView:cell.imageView fromCache:self.globalCache.imageCache forIndexPath:indexPath];
    } else {
        //Do default image for the business.
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"png"];
        UIImage *testImage = [UIImage imageWithContentsOfFile:filePath];
        cell.imageView.image = testImage;
    }
    
    NSString *reviewImageURL = [[self.businesses objectAtIndex:indexPath.row] objectForKey:@"rating_img_url_small"];
    if (reviewImageURL) {
        [self applyImageFromURl:reviewImageURL toImageView:cell.reviewStarImageView fromCache:self.globalCache.reviewImageCache forIndexPath:indexPath];
    }
    
    return cell;
}

- (void) applyImageFromURl:(NSString *)imageURL toImageView:(UIImageView *)imageView fromCache:(NSMutableDictionary *)cache forIndexPath:(NSIndexPath *)indexPath {
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

- (void)fetchGeoCodesForBusiness:(NSArray *)businesses {
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AppConfig" ofType:@"plist"]];
    
    NSURL *geoCodeURL = [NSURL URLWithString:@"https://maps.googleapis.com/maps/api/geocode/json"];
    
    for (NSDictionary *business in businesses) {
        OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:geoCodeURL consumer:nil token:nil realm:nil signatureProvider:nil];
        [request setHTTPMethod:@"GET"];
        NSDictionary *location = [business objectForKey:@"location"];
        NSString *add = [[location objectForKey:@"address"] firstObject];
        NSString *address = [add stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        NSString *addressString = [NSString stringWithFormat:@"%@+%@+%@+%@", address, [location objectForKey:@"state_code"], [location objectForKey:@"postal_code"],[location objectForKey:@"country_code"]];

        OARequestParameter * qParam1 = [[OARequestParameter alloc] initWithName:@"address" value:addressString];
        OARequestParameter * qParam2 = [[OARequestParameter alloc] initWithName:@"sensor" value:@"true"];
        OARequestParameter * qParam3 = [[OARequestParameter alloc] initWithName:@"key" value:[dictionary objectForKey:@"GeoCodeKey"]];
        OARequestParameter * qParam4 = [[OARequestParameter alloc] initWithName:@"businessName" value:[business objectForKey:@"name"]];
        [request setParameters:[NSArray arrayWithObjects:qParam1,qParam2,qParam3,qParam4,nil]];
        
        OADataFetcher *fetcher = [[OADataFetcher alloc] init];
        [fetcher fetchDataWithRequest:request
                             delegate:self
                    didFinishSelector:@selector(foundGeoCode:withData:)
                      didFailSelector:nil];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == [self.businesses count] - 1 && [self.businesses count] < self.totalResults) {
        [self.activityIndicator startAnimating];
        //[self downloadDataForApi:@"search" withLimit:nil];
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:10];
        NSString *latLongString = [NSString stringWithFormat:@"%f,%f", self.latitude, self.longitude];
        [params setObject:latLongString forKey:@"ll"];
        [params setObject:[[NSNumber alloc] initWithInt:[self.sortValue ]] forKey:@"sortValue"];
        [params setObject:[[NSNumber alloc] initWithInt:[self.businesses count]] forKey:@"offset"];
        [self downloadDataForApi:@"search" withLimit:nil andParams:params];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    if (location) {
        self.latitude = location.coordinate.latitude;
        self.longitude = location.coordinate.longitude;
        [self.locationManager stopUpdatingLocation];
        [self downloadDataForApi:@"search" withLimit:nil];
        [self setupMapWithLocation:location.coordinate];
    }
}

- (void) foundGeoCode:(OAServiceTicket *)ticket withData:(NSMutableData *) responseData {
    
    NSString *response= [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&err];
    NSArray *results = [json objectForKey:@"results"];
    NSDictionary *coordinate = [[[results firstObject] objectForKey:@"geometry"] objectForKey:@"location"];
    
    OARequestParameter *params = [ticket.request.parameters lastObject];
    CLLocationCoordinate2D busLoc = CLLocationCoordinate2DMake([[coordinate objectForKey:@"lat"] doubleValue], [[coordinate objectForKey:@"lng"] doubleValue]);
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:busLoc];
    [annotation setTitle:params.value];
    [self.locationsArray addObject:annotation];
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    NSString *ident = @"pin";
    MKPinAnnotationView *annView=(MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:ident];
    if(annView == nil){
        annView=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ident];
        annView.animatesDrop=TRUE;
        annView.canShowCallout = YES;
        annView.pinColor=MKPinAnnotationColorPurple;
    }
    
    if([[annotation title] isEqualToString:@"Current Location"]){
        annView.pinColor=MKPinAnnotationColorRed;
    }
    return annView;
}

- (void)sortButtonSelected:(NSNumber *)sortValue {
    [self dismissViewControllerAnimated:YES completion:nil];
    if ([sortValue integerValue] != self.sortValue) {
        self.sortValue = [sortValue integerValue];
        NSUInteger totalBusinessesFetchedSoFar = [self.businesses count];
        [self.businesses removeAllObjects];
        [self.locationsArray removeAllObjects];
        [self.activityIndicator startAnimating];
        if (totalBusinessesFetchedSoFar > 20) totalBusinessesFetchedSoFar = 20;
        [self downloadDataForApi:@"search" withLimit:[NSString stringWithFormat:@"%d", totalBusinessesFetchedSoFar]];
        self.tableView.hidden = YES;
        [self.tableView setScrollsToTop:YES];
    }
}

@end
