//
//  SRAddSourceViewController.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/26/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import "SRAddSourceViewController.h"
#import "HTMLNode.h"
#import "HTMLParser.h"
#import "AFHTTPRequestOperationManager.h"
#import "SRSource.h"
#import "MWFeedInfo.h"
#import "MWFeedParser.h"
#import "UIViewController+CWPopup.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@interface SRAddSourceViewController () <SRSourceDelegate, UITextFieldDelegate>
{
    NSString *_faviconLink;
    
    /** It's possible that there are multiple RSS feed sources in one HTML page, thus we should process all of them. */
    int sourcesProcessed;
}

@property (nonatomic) IBOutlet UIView *dialog;
@property (nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic) IBOutlet UITextField *urlField;
@property (nonatomic) NSMutableArray *sources;
@property (nonatomic) AFHTTPRequestOperationManager *manager;

- (IBAction)dismiss:(id)sender;
- (IBAction)add:(id)sender;

@end

@implementation SRAddSourceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.urlField.autocorrectionType = UITextAutocorrectionTypeNo;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.sources = [NSMutableArray new];
    sourcesProcessed = 0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Setup screen name tracking in GA.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass([self class])];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismiss:(id)sender
{
    [self.manager.operationQueue cancelAllOperations];
    [self.delegate addSourceViewControllerDidDismiss];
}

- (IBAction)add:(id)sender
{
    [self.urlField resignFirstResponder];
    
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    if (![self.urlField.text hasPrefix:@"http"]) {
        self.urlField.text = [NSString stringWithFormat:@"http://%@", self.urlField.text];
    }
    
    NSURL *url = [NSURL URLWithString:self.urlField.text];
    
    [self parseForFeedFromUrl:url];
}

- (void)parseForFeedFromUrl:(NSURL *)feedUrl
{
    // Check if url is pointing to a website or a feed.  If it is pointing to a website, parse HTML for feed url.
    self.manager = [AFHTTPRequestOperationManager manager];
    
    // Customize the user agent string so the returned HTML is always for desktop, where there will most likely be an embedded link to the feed.
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.73.11 (KHTML, like Gecko) Version/7.0.1 Safari/537.73.11" forHTTPHeaderField:@"User-Agent"];
    
    [self.manager setRequestSerializer:requestSerializer];
    [self.manager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    [self.manager GET:feedUrl.absoluteString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error = nil;
        HTMLParser *parser = [[HTMLParser alloc] initWithString:operation.responseString error:&error];
        if (error) {
            DebugLog(@"HTML parser error: %@", error);
            //TODO: Handle if response data can not be parsed.
        }
        
        // Check if response is HTML or feed XML.
        if (![parser head] && ([[parser body] findChildTag:@"rss"] || [[parser body] findChildTag:@"feed"])) {
            // Feed XML.  Process into feed item.
            // After feed is processed, will call delegate to pass along the feed source object.
            
            [self.sources addObject:[SRSource new]];
            SRSource *source = (SRSource *)self.sources.lastObject;
            source.feedLink = operation.request.URL.absoluteString;
            source.faviconLink = _faviconLink;
            source.delegate = self;
            [source refresh];
        }
        else {
            // HTML, parse for feed url.
            BOOL feedUrlExists = NO;
            for (HTMLNode *node in [[parser head] findChildTags:@"link"]) {
                if ([[[node getAttributeNamed:@"rel"] lowercaseString] isEqualToString:@"icon"] ||
                    [[[node getAttributeNamed:@"rel"] lowercaseString] isEqualToString:@"shortcut icon"]) {
                    _faviconLink = [node getAttributeNamed:@"href"];
                    
                    if (![_faviconLink hasPrefix:@"http"] && [_faviconLink hasPrefix:@"//"]) {
                        _faviconLink = [_faviconLink stringByReplacingOccurrencesOfString:@"//" withString:@"http://"];
                    }
                    
                    if ([_faviconLink hasPrefix:@"/"]) {
                        _faviconLink = [operation.request.URL.absoluteString stringByAppendingString:_faviconLink];
                    }
                    
                    DebugLog(@"Favicon link: %@", _faviconLink);
                }
                
                if ([[[node getAttributeNamed:@"type"] lowercaseString] isEqualToString:@"application/rss+xml"]) {
                    NSString *urlString = [node getAttributeNamed:@"href"];
                    
                    if (![urlString hasPrefix:@"http"] && [urlString hasPrefix:@"//"]) {
                        urlString = [urlString stringByReplacingOccurrencesOfString:@"//" withString:@"http://"];
                    }
                    
                    if ([urlString hasPrefix:@"/"]) {
                        urlString = [operation.request.URL.absoluteString stringByAppendingString:urlString];
                    }
                    
                    DebugLog(@"Found feed url: %@", urlString);
                    
                    feedUrlExists = YES;
                    [self parseForFeedFromUrl:[NSURL URLWithString:urlString]];
                }
            }
            
            if (!feedUrlExists) {
                [self parseFeedErrorResponse];
                
                DebugLog(@"Feed URL does not exist.");
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self parseFeedErrorResponse];
        
        DebugLog(@"Error trying to add news source: %@, error: %@", operation.request.URL, error);
    }];
}

- (void)parseFeedErrorResponse
{
    _faviconLink = nil;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Feed Found" message:@"No feeds were found in the url provided." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    
    [self.activityIndicator stopAnimating];
    self.activityIndicator.hidden = YES;
    
    [self.delegate addSourceViewController:self failedToRetrieveSourceWithURL:self.urlField.text];
}

#pragma mark - SRSourceDelegate

- (void)didFinishRefreshingSource:(SRSource *)source withError:(NSError *)error
{
    DebugLog(@"Source parsing ended...");
    
    [self.delegate addSourceViewController:self didRetrieveSource:source];
    
    sourcesProcessed++;
    if (sourcesProcessed == self.sources.count) {
        [self dismiss:self];
        [self.delegate addSourceViewControllerDidFinishAddingAllSources:self];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self add:self];
    return YES;
}

@end
