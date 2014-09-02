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
#define IMAGE_SIZE CGSizeMake(25.0, 25.0)

@interface SRMainContentViewController () <UIWebViewDelegate, UIActivityItemSource>
{
    BOOL _readingOriginalLink;
}

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIView *activityIndicatorBackgroundView;
@property (nonatomic) UIBarButtonItem *switchArticleViewButton;
@property (nonatomic) UIBarButtonItem *likeButton;
@property (nonatomic) UIBarButtonItem *bookmarkButton;
@property (nonatomic) UIBarButtonItem *shareButton;
@property (nonatomic) MWFeedItem *feedItem;
@property (nonatomic) NSString *shortenedURLString;

- (void)switchArticleView:(id)sender;
- (void)likeArticle:(id)sender;

@end

@implementation SRMainContentViewController

- (instancetype)initWithFeedItem:(MWFeedItem *)feedItem
{
    self = [super init];
    if (self) {
        self.feedItem = feedItem;
        
        // Customize the back button.
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"backward-7.png"] resizeImageToSize:IMAGE_SIZE]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(dismiss:)];
        self.navigationItem.leftBarButtonItem = backButton;
        
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            self.navigationItem.title = self.feedItem.title;
        }
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
    
    UISwipeGestureRecognizer *swipeToGoBack = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
    [self.view addGestureRecognizer:swipeToGoBack];
    
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    self.activityIndicatorBackgroundView.hidden = NO;
    self.activityIndicatorBackgroundView.layer.borderWidth = 2.0;
    self.activityIndicatorBackgroundView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.activityIndicatorBackgroundView.layer.cornerRadius = 5.0;
    self.activityIndicatorBackgroundView.clipsToBounds = YES;
    
    self.webView.delegate = self;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.feedItem.link]]];
    _readingOriginalLink = YES;
    
    [self shortenURL];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.likeButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"star-7.png"] resizeImageToSize:IMAGE_SIZE]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(likeArticle:)];

    
    self.switchArticleViewButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"glasses-7.png"] resizeImageToSize:IMAGE_SIZE]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(switchArticleView:)];
    
    self.bookmarkButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"bookmark-7.png"] resizeImageToSize:IMAGE_SIZE]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(bookmarkArticle:)];
    
    if (self.feedItem.bookmarked) {
        self.bookmarkButton.image = [[UIImage imageNamed:@"bookmark-7-active.png"] resizeImageToSize:IMAGE_SIZE];
    }
    
    self.shareButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"share-7.png"] resizeImageToSize:IMAGE_SIZE]
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(shareArticle:)];
    
    self.navigationItem.rightBarButtonItems = @[ self.likeButton, self.shareButton, self.bookmarkButton, self.switchArticleViewButton ];
    
    self.likeButton.enabled = !self.feedItem.userLiked;
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (UIInterfaceOrientationIsPortrait(fromInterfaceOrientation)) {
        self.navigationItem.title = self.feedItem.title;
    }
    else {
        self.navigationItem.title = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismiss:(id)sender
{
    // If the swipe gesture triggered the dismiss action, make sure it was from within 80 px of the view, and a swipe to right.
    // This is for mimicking the standard swipe gesture behavior that belongs to the standard back button.
    if ([sender isKindOfClass:[UISwipeGestureRecognizer class]]) {
        UISwipeGestureRecognizer * swipeGestureRecognizer = (UISwipeGestureRecognizer *)sender;
        if (!([swipeGestureRecognizer locationInView:self.view].x < 80 && swipeGestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight)) {
            return;
        }
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Utility methods

- (void)shortenURL
{
    NSURL *tinyURLApi = [NSURL URLWithString:[NSString stringWithFormat:@"http://tinyurl.com/api-create.php?url=%@", self.feedItem.link]];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:tinyURLApi]
                                       queue:[NSOperationQueue new]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (data && !connectionError) {
                                   self.shortenedURLString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                               }
                           }];
}

#pragma mark - Custom actions

- (void)switchArticleView:(id)sender
{
    NSString *message;
    
    UIBarButtonItem *barButtonItem = (UIBarButtonItem *)sender;

    if (!_readingOriginalLink) {
        [barButtonItem setImage:[[UIImage imageNamed:@"glasses-7.png"] resizeImageToSize:IMAGE_SIZE]];
        
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.feedItem.link]]];
        
        _readingOriginalLink = YES;
        
        message = @"Reading original article";
    }
    else {
        [barButtonItem setImage:[[UIImage imageNamed:@"compass-7.png"] resizeImageToSize:IMAGE_SIZE]];
        
        // Encode the url for passing to Readability API.
        NSString *encodedUrlString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                           NULL,
                                                                                                           (CFStringRef)self.feedItem.link,
                                                                                                           NULL,
                                                                                                           (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                           kCFStringEncodingUTF8)
                                                                   );
        
        NSString *readabilityUrl = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", encodedUrlString];
        
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:readabilityUrl]]];
        
        _readingOriginalLink = NO;
        
        message = @"Reading through Readability";
    }
    
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithMessage:message];
    [self.navigationController.view addSubview:msgController.view];
    [msgController animate];
}

- (void)likeArticle:(id)sender
{
    DebugLog(@"Liked article.");
    
    [[SRTextFilteringManager sharedManager] processFeedItemAsLiked:self.feedItem];
    
    self.likeButton.enabled = NO;
    
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithMessage:@"Marked as interesting"];
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
        self.feedItem.bookmarkedDate = nil;
        
        [barButtonItem setImage:[[UIImage imageNamed:@"bookmark-7.png"] resizeImageToSize:IMAGE_SIZE]];
    }
    else {
        DebugLog(@"Bookmared article: %@", self.feedItem);
        message = @"Bookmarked";
        
        self.feedItem.bookmarked = YES;
        self.feedItem.bookmarkedDate = [NSDate date];
        
        [barButtonItem setImage:[[UIImage imageNamed:@"bookmark-7-active.png"] resizeImageToSize:IMAGE_SIZE]];
    }
    
    [[SRSourceManager sharedManager] saveSources];
    
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithMessage:message];
    [self.navigationController.view addSubview:msgController.view];
    [msgController animate];
    
    [self.delegate refresh:self];
}

- (void)shareArticle:(id)sender
{
    DebugLog(@"Sharing article...");
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self]
                                                                                         applicationActivities:nil];
    [self.navigationController presentViewController:activityViewController
                                            animated:YES
                                          completion:nil];
}

#pragma mark - UIActivityItemSource methods

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return [NSURL URLWithString:self.shortenedURLString.length ? self.shortenedURLString : self.feedItem.link];
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    if ([activityType isEqualToString:UIActivityTypeAddToReadingList] ||
        [activityType isEqualToString:UIActivityTypeCopyToPasteboard] ||
        [activityType isEqualToString:UIActivityTypeAirDrop]) {
        return [NSURL URLWithString:self.shortenedURLString.length ? self.shortenedURLString : self.feedItem.link];
    }
    else {
        return [NSString stringWithFormat:@"%@: %@", @"I discovered this article using Smart Reader for iOS", self.shortenedURLString.length ? self.shortenedURLString : self.feedItem.link];
    }
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
{
    return self.feedItem.title;
}

#pragma mark - UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.activityIndicatorBackgroundView.hidden = NO;
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;
    self.activityIndicatorBackgroundView.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;
    self.activityIndicatorBackgroundView.hidden = YES;
}

@end
