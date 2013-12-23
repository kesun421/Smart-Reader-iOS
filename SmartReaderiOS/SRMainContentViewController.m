//
//  SRMainViewController.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/25/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import "SRMainContentViewController.h"
#import "MWFeedItem.h"
#import "NSString+HTML.h"
#import "AFHTTPRequestOperationManager.h"
#import "HTMLParser.h"
#import "HTMLNode.h"

#define READABILITY_KEY @"c0557e5c516a1c9879affe72fb636dfd2bdef62c"

@interface SRMainContentViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic) MWFeedItem *feedItem;

@end

@implementation SRMainContentViewController

- (instancetype)initWithFeedItem:(MWFeedItem *)feedItem
{
    self = [super init];
    if (self) {
        self.feedItem = feedItem;
        self.navigationItem.title = self.feedItem.title;
    }
    return self;
}

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
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString *readabilityApiUrl = [NSString stringWithFormat:@"https://readability.com/api/content/v1/parser?url=%@&token=%@", self.feedItem.link, READABILITY_KEY];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:readabilityApiUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        [self.webView loadHTMLString:dict[@"content"] baseURL:nil];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
