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
    [self.delegate dismissAddSourceViewController:self];
}

- (IBAction)add:(id)sender
{
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    NSURL *url = [NSURL URLWithString:self.urlField.text];
    
    [self parseForFeedFromUrl:url];
}

- (void)parseForFeedFromUrl:(NSURL *)feedUrl
{
    // Check if url is pointing to a website or a feed.  If it is pointing to a website, parse HTML for feed url.
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager setResponseSerializer:[AFHTTPResponseSerializer new]];
    [manager GET:feedUrl.absoluteString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        HTMLParser *parser = [[HTMLParser alloc] initWithString:responseString error:&error];
        if (error) {
            DebugLog(@"HTML parser error: %@", error);
            //TODO: Handle if response data can not be parsed.
        }
        
        // Check if response is HTML or feed XML.
        if (![parser head] && ([[parser body] findChildTag:@"rss"] || [[parser body] findChildTag:@"feed"])) {
            // Feed XML.  Process into feed item.
            
            MWFeedParser *feedParser = [[MWFeedParser alloc] initWithFeedURL:operation.request.URL];
            feedParser.delegate = self;
            feedParser.feedParseType = ParseTypeFull;
            feedParser.connectionType = ConnectionTypeAsynchronously;
            [feedParser parse];
            
            [self.delegate addSourceViewController:self didRetrieveSource:[SRSource new]];
        }
        else {
            // HTML, parse for feed url.
            for (HTMLNode *node in [[parser head] findChildTags:@"link"]) {
                if ([[node getAttributeNamed:@"type"] isEqualToString:@"application/rss+xml"]) {
                    DebugLog(@"Found feed url: %@", [node getAttributeNamed:@"href"]);
                    
                    [self parseForFeedFromUrl:[NSURL URLWithString:[node getAttributeNamed:@"href"]]];
                }
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
}

- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error
{
    DebugLog(@"Feed parsing failed with error: %@", error);
}

@end
