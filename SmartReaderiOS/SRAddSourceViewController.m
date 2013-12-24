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

@interface SRAddSourceViewController () <MWFeedParserDelegate>
{
    NSString *_faviconLink;
}

@property (nonatomic) IBOutlet UIView *dialog;
@property (nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic) IBOutlet UITextField *urlField;
@property (nonatomic) SRSource *source;

- (IBAction)dismiss:(id)sender;
- (IBAction)add:(id)sender;

@end

@implementation SRAddSourceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.backgroundColor = [UIColor lightGrayColor];
        self.dialog.layer.cornerRadius = 20.0;
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismiss:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    // Customize the user agent string so the returned HTML is always for desktop, where there will most likely be an embedded link to the feed.
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    [requestSerializer setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.73.11 (KHTML, like Gecko) Version/7.0.1 Safari/537.73.11" forHTTPHeaderField:@"User-Agent"];
    
    [manager setRequestSerializer:requestSerializer];
    [manager setResponseSerializer:[AFHTTPResponseSerializer serializer]];
    [manager GET:feedUrl.absoluteString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
            
            MWFeedParser *feedParser = [[MWFeedParser alloc] initWithFeedURL:operation.request.URL];
            feedParser.delegate = self;
            feedParser.feedParseType = ParseTypeFull;
            feedParser.connectionType = ConnectionTypeAsynchronously;
            [feedParser parse];
        }
        else {
            // HTML, parse for feed url.
            BOOL feedUrlExists = NO;
            for (HTMLNode *node in [[parser head] findChildTags:@"link"]) {
                if ([[[node getAttributeNamed:@"rel"] lowercaseString] isEqualToString:@"icon"] ||
                    [[[node getAttributeNamed:@"rel"] lowercaseString] isEqualToString:@"shortcut icon"]) {
                    _faviconLink = [node getAttributeNamed:@"href"];
                }
                
                if ([[[node getAttributeNamed:@"type"] lowercaseString] isEqualToString:@"application/rss+xml"]) {
                    NSString *urlString = [node getAttributeNamed:@"href"];
                    
                    DebugLog(@"Found feed url: %@", urlString);
                    
                    if (![urlString hasPrefix:@"http"]) {
                        if ([urlString hasPrefix:@"//"]) {
                            urlString = [urlString stringByReplacingOccurrencesOfString:@"//" withString:@""];
                        }
                        
                        urlString = [NSString stringWithFormat:@"http://%@", urlString];
                    }
                    
                    feedUrlExists = YES;
                    [self parseForFeedFromUrl:[NSURL URLWithString:urlString]];
                }
            }
            
            if (!feedUrlExists) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Feed Found" message:@"No feeds were found in the url provided." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                
                [self.activityIndicator stopAnimating];
                self.activityIndicator.hidden = YES;
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DebugLog(@"Error: %@", error);
    }];
}

#pragma mark - MWFeedParserDelegate methods

- (void)feedParserDidStart:(MWFeedParser *)parser
{
    DebugLog(@"Feed parsing stated...");
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info
{
    DebugLog(@"Parsed feed info: %@", info);
    
    self.source = [SRSource new];
    self.source.feedInfo = info;
    self.source.faviconLink = _faviconLink;
    self.source.lastUpdatedDate = [NSDate date];
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item
{
    DebugLog(@"Parsed feed item: %@", item);
    
    [self.source addFeedItem:item];
}

- (void)feedParserDidFinish:(MWFeedParser *)parser
{
    DebugLog(@"Feed parsing ended...");
    
    [self.delegate addSourceViewController:self didRetrieveSource:self.source];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error
{
    DebugLog(@"Feed parsing failed with error: %@", error);
}

@end
