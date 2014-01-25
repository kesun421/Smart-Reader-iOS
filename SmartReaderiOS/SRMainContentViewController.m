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
#import "UIImage+Extensions.h"

// #define READABILITY_KEY @"c0557e5c516a1c9879affe72fb636dfd2bdef62c"
#define IMAGE_SIZE CGSizeMake(22.0, 22.0)

@interface SRMainContentViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;
@property (nonatomic) UIBarButtonItem *switchArticleViewButton;
@property (nonatomic) UIBarButtonItem *likeButton;
@property (nonatomic) UIBarButtonItem *dislikeButton;
@property (nonatomic) UIBarButtonItem *bookmarkButton;
@property (nonatomic) MWFeedItem *feedItem;

- (void)switchArticleView:(id)sender;
- (void)likeArticle:(id)sender;
- (void)unlikeArticle:(id)sender;

@end

@implementation SRMainContentViewController

- (instancetype)initWithFeedItem:(MWFeedItem *)feedItem
{
    self = [super init];
    if (self) {
        self.feedItem = feedItem;
//        self.navigationItem.title = self.feedItem.title;
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
    
    self.likeButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"star.png"] resizeImageToSize:IMAGE_SIZE]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(likeArticle:)];
    
    self.dislikeButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"forbidden.png"] resizeImageToSize:IMAGE_SIZE]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(unlikeArticle:)];
    
    self.switchArticleViewButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"link.png"] resizeImageToSize:IMAGE_SIZE]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(switchArticleView:)];
    
    self.bookmarkButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"bookmark-7.png"] resizeImageToSize:IMAGE_SIZE]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(bookmarkArticle:)];
    
    if (self.feedItem.bookmarked) {
        self.bookmarkButton.image = [[UIImage imageNamed:@"bookmark-7-remove.png"] resizeImageToSize:IMAGE_SIZE];
    }
    
    self.navigationItem.rightBarButtonItems = @[ self.dislikeButton, self.likeButton, self.bookmarkButton, self.switchArticleViewButton ];
    
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

- (void)switchArticleView:(id)sender
{
    static BOOL readingOriginal = NO;
    
    UIBarButtonItem *barButtonItem = (UIBarButtonItem *)sender;
    
    if (!readingOriginal) {
        [barButtonItem setImage:[[UIImage imageNamed:@"text-pic-left.png"] resizeImageToSize:IMAGE_SIZE]];
        
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.feedItem.link]]];
        
        readingOriginal = YES;
    }
    else {
        [barButtonItem setImage:[[UIImage imageNamed:@"link.png"] resizeImageToSize:IMAGE_SIZE]];
        
        NSString *readabilityUrl = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", self.feedItem.link];
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:readabilityUrl]]];
        
        readingOriginal = NO;
    }
}

- (void)likeArticle:(id)sender
{
    DebugLog(@"Liked article.");
    
    [[SRTextFilteringManager sharedManager] processFeedItem:self.feedItem AsLiked:YES];
    
    self.likeButton.enabled = NO;
    self.dislikeButton.enabled = YES;
    
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithMessage:@"Liked"];
    [self.navigationController.view addSubview:msgController.view];
    [msgController animate];
}

- (void)unlikeArticle:(id)sender
{
    DebugLog(@"Unliked article.");
    
    [[SRTextFilteringManager sharedManager] processFeedItem:self.feedItem AsLiked:NO];
    
    self.likeButton.enabled = YES;
    self.dislikeButton.enabled = NO;
    
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithMessage:@"Unliked"];
    [self.navigationController.view addSubview:msgController.view];
    [msgController animate];
}

- (void)bookmarkArticle:(id)sender
{
    NSString *message;
    
    UIBarButtonItem *barButtonItem = (UIBarButtonItem *)sender;
    
    if (self.feedItem.bookmarked) {
        DebugLog(@"Unbookmared article: %@", self.feedItem);
        message = @"Unbookmarked";
        
        self.feedItem.bookmarked = NO;
        
        [barButtonItem setImage:[[UIImage imageNamed:@"bookmark-7.png"] resizeImageToSize:IMAGE_SIZE]];
    }
    else {
        DebugLog(@"Bookmared article: %@", self.feedItem);
        message = @"Bookmarked";
        
        self.feedItem.bookmarked = YES;
        
        [barButtonItem setImage:[[UIImage imageNamed:@"bookmark-7-remove.png"] resizeImageToSize:IMAGE_SIZE]];
    }
    
    [[SRSourceManager sharedManager] saveSources];
    
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithMessage:message];
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
