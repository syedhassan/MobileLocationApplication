//
//  BLYBaseViewController.m
//  MobileLocationApplication
//
//  Created by Sana Hassan on 3/2/14.
//  Copyright (c) 2014 Belly. All rights reserved.
//

#import "BLYBaseViewController.h"
#import "OAuthConsumer.h"
#import "BLYTableViewCell.h"

@interface BLYBaseViewController ()

@end

@implementation BLYBaseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void) applyImageFromURl:(NSString *)imageURL toImageView:(UIImageView *)imageView fromCache:(NSMutableDictionary *)cache forCell:(BLYTableViewCell *)cell {
//    UIImage *image = [cache objectForKey:imageURL];
//    if (image) {
//        imageView.image = image;
//    } else {
//        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
//        dispatch_async(queue, ^(void) {
//            NSIndexPath *cellIndex = indexPath;
//            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
//            UIImage *img = [[UIImage alloc] initWithData:imageData];
//            if (img) {
//                [cache setObject:img forKey:imageURL];
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    BLYTableViewCell *c = (BLYTableViewCell *)[self.tableView cellForRowAtIndexPath:cellIndex];
//                    if ([[self.tableView visibleCells] containsObject:c]) {
//                        if (c) {
//                            imageView.image = img;
//                            [c setNeedsLayout];
//                        }
//                    }
//                });
//            }
//        });
//    }
//}

- (void)downloadDataForApi:(NSString *)api withLimit:(NSString *)limit andParams:(NSDictionary*)params {
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
        OARequestParameter * qParam1 = [[OARequestParameter alloc] initWithName:@"ll" value:[params objectForKey:@"ll"]];
        OARequestParameter * qParam2 = [[OARequestParameter alloc] initWithName:@"sort" value:[NSString stringWithFormat:@"%d", [[params objectForKey:@"sortValue"] integerValue]]];
        if (!limit) limit = @"10";
        OARequestParameter * qParam3 = [[OARequestParameter alloc] initWithName:@"offset" value:[NSString stringWithFormat:@"%d", [[params objectForKey:@"offset"] integerValue]]];
        OARequestParameter * qParam4 = [[OARequestParameter alloc] initWithName:@"limit" value:limit];
        [request setParameters:[NSArray arrayWithObjects:qParam1,qParam2,qParam3,qParam4,nil]];
    }
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(requestDidFinishWithData:)
                  didFailSelector:@selector(requestDidFailWithError:)];
}

- (void)requestDidFinishWithData:(OAServiceTicket *)ticket {
    //Extended classes should implement this method.
}

- (void)requestDidFailWithError:(OAServiceTicket *)ticket {
    NSLog(@"ERROR!!!! %@",ticket);
}

@end
