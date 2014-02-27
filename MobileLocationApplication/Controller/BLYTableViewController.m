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
#import <QuartzCore/QuartzCore.h>

@interface BLYTableViewController ()
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSNumber *pageNumber;
@property (strong, atomic) NSCache *imageCache;
@property (strong, atomic) NSCache *reviewStartImageCache;
@property (strong, nonatomic) NSMutableArray *businesses;
@end

@implementation BLYTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
    [self downloadData];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) setup {
    UILabel *locations = [[UILabel alloc] init];
    locations.text = @"Locations";
    locations.textColor = [UIColor whiteColor];
    CGSize size = [locations.text sizeWithAttributes:@{NSFontAttributeName:locations.font}];
    locations.frame = CGRectMake(0, 0, size.width, size.height);
    self.navigationItem.titleView = locations;
    self.businesses = [[NSMutableArray alloc] initWithCapacity:60];
    self.pageNumber = [[NSNumber alloc] initWithInt:0];
    self.imageCache = [[NSCache alloc] init];
    self.reviewStartImageCache = [[NSCache alloc] init];
    self.tableView.hidden = YES;
    self.activityIndicator.transform = CGAffineTransformMakeScale(2.0f, 2.0f);
}

- (void) downloadData {
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]];
    
    OAConsumer *consumer = [[OAConsumer alloc] initWithKey:[dictionary objectForKey:@"ConsumerKey"] secret:[dictionary objectForKey:@"ConsumerSecret"]];
    OAToken *token = [[OAToken alloc] initWithKey:[dictionary objectForKey:@"Token"] secret:[dictionary objectForKey:@"TokenSecret"]];
    NSURL *url = [NSURL URLWithString:@"http://api.yelp.com/v2/search"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:consumer
                                                                      token:token
                                                                      realm:nil
                                                          signatureProvider:nil];
    
    [request setHTTPMethod:@"GET"];
    
    OARequestParameter * qParam1 = [[OARequestParameter alloc] initWithName:@"term" value:@"food"];
    OARequestParameter * qParam2 = [[OARequestParameter alloc] initWithName:@"ll" value:@"41.882191,-87.640452"];
    OARequestParameter * qParam4 = [[OARequestParameter alloc] initWithName:@"sort" value:@"1"];
    OARequestParameter * qParam3 = [[OARequestParameter alloc] initWithName:@"offset" value:[NSString stringWithFormat:@"%d", [self.businesses count]]];
    [request setParameters:[NSArray arrayWithObjects:qParam1,qParam2,qParam3,qParam4, nil]];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestDidFinishWithData:)
                  didFailSelector:@selector(requestDidFailWithError:)];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)requestDidFinishWithData:(OAServiceTicket *)ticket {
    NSString *response= [[NSString alloc] initWithData:ticket.data encoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&err];
    
    NSArray *bsn = [json objectForKey:@"businesses"];
    [self.businesses addObjectsFromArray:bsn];
    
    self.pageNumber = [NSNumber numberWithInt:[self.pageNumber integerValue] + 1];
    
    [self.tableView reloadData];
    NSLog(@"Total No of rows = %d", [self.businesses count]);
    
    self.tableView.hidden = NO;
    self.backgroundView.hidden = NO;
    self.backgroundView.backgroundColor = [UIColor whiteColor];
    [self.activityIndicator stopAnimating];
}

- (void)requestDidFailWithError:(OAServiceTicket *)ticket {
    NSLog(@"ERROR!!!!");
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
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
    
    cell.imageView.image = nil;
    
    cell.businessName.text = [[self.businesses objectAtIndex:indexPath.row] objectForKey:@"name"];
    
    
    NSNumber *distance = [[self.businesses objectAtIndex:indexPath.row] objectForKey:@"distance"];
    
    if (distance) {
        CGFloat distanceInMts = [distance floatValue];
        cell.businessDistance.text = [NSString stringWithFormat:@"%.2f miles away", (distanceInMts/1069)];
    }
    
    cell.businessType.text = @"Not sure";
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
    }
    
    NSString *reviewImageURL = [[self.businesses objectAtIndex:indexPath.row] objectForKey:@"rating_img_url"];
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
    if(indexPath.row == [self.businesses count] - 3) {
        NSLog(@"Reloading more data");
        [self.activityIndicator startAnimating];
        [self downloadData];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];

    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
 
 */

@end
