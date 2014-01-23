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
//#import "AFHTTPRequestOperationManager.h"
#import "HTMLParser.h"
#import "HTMLNode.h"
#import "SRTextFilteringManager.h"
#import "SRSourceManager.h"
#import "SRMessageViewController.h"

// #define READABILITY_KEY @"c0557e5c516a1c9879affe72fb636dfd2bdef62c"

@interface SRMainContentViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *switchArticleViewButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *likeButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *dislikeButton;
@property (nonatomic) MWFeedItem *feedItem;

- (IBAction)switchArticleView:(id)sender;
- (IBAction)likeArticle:(id)sender;
- (IBAction)unlikeArticle:(id)sender;

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
    
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    self.webView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString *readabilityUrl = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", self.feedItem.link];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:readabilityUrl]]];
    
    self.likeButton.enabled = !self.feedItem.userLiked;
    self.dislikeButton.enabled = !self.feedItem.userUnliked;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.feedItem.read = YES;
    
    [[SRSourceManager sharedManager] saveSources];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.delegate refresh:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Custom actions

- (IBAction)switchArticleView:(id)sender
{
    static BOOL readingOriginal = NO;
    
    UIBarButtonItem *barButtonItem = (UIBarButtonItem *)sender;
    
    if (!readingOriginal) {
        [barButtonItem setImage:[UIImage imageNamed:@"163-glasses-1.png"]];
        
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.feedItem.link]]];
        
        readingOriginal = YES;
    }
    else {
        [barButtonItem setImage:[UIImage imageNamed:@"113-navigation.png"]];
        
        NSString *readabilityUrl = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", self.feedItem.link];
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:readabilityUrl]]];
        
        readingOriginal = NO;
    }
}

- (IBAction)likeArticle:(id)sender
{
    DebugLog(@"Liked article.");
    
    [[SRTextFilteringManager sharedManager] processFeedItem:self.feedItem AsLiked:YES];
    
    self.likeButton.enabled = NO;
    self.dislikeButton.enabled = YES;
    
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithSize:CGSizeMake(180.0, 40.0) message:@"Liked..."];
    [self.navigationController.view addSubview:msgController.view];
    [msgController animate];
}

- (IBAction)unlikeArticle:(id)sender
{
    DebugLog(@"Unliked article.");
    
    [[SRTextFilteringManager sharedManager] processFeedItem:self.feedItem AsLiked:NO];
    
    self.likeButton.enabled = YES;
    self.dislikeButton.enabled = NO;
    
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithSize:CGSizeMake(180.0, 40.0) message:@"Unliked..."];
    [self.navigationController.view addSubview:msgController.view];
    [msgController animate];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;
}

@end
