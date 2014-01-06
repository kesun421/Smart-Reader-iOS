//
//  SRMainTableViewController.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/25/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import "SRMainTableViewController.h"
#import "SRFileUtility.h"
#import "SRSecondaryTableViewController.h"
#import "SRAddSourceViewController.h"
#import "SRSource.h"
#import "MWFeedInfo.h"
#import "UIImageView+AFNetworking.h"
#import "MWFeedParser.h"
#import "MWFeedInfo.h"
#import "MWFeedItem.h"
#import "SRSourceManager.h"
#import "SRTextFilteringManager.h"

@interface SRMainTableViewController () <SRAddSourceViewControllerDelegate, SRSourceManagerDelegate, SRTextFilteringManagerDelegate>

@property (nonatomic) SRSourceManager *sourceManager;
@property (nonatomic) NSArray *likeableFeedItems;

@end

@implementation SRMainTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.sourceManager = [SRSourceManager sharedManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    [self.sourceManager loadSources];
    self.sourceManager.mainDelegate = self;
    [self.sourceManager refreshSources];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.likeableFeedItems.count ? self.sourceManager.sources.count + 1 : self.sourceManager.sources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (self.likeableFeedItems.count && indexPath.row == 0) {
        [cell.imageView setImageWithURL:nil];
        cell.textLabel.text = [NSString stringWithFormat:@"Suggested Reading - %d", self.likeableFeedItems.count];
        cell.detailTextLabel.text = nil;
    }
    else {
        int index = self.likeableFeedItems.count ? indexPath.row - 1 : indexPath.row;
        SRSource *source = self.sourceManager.sources[index];
        
        [cell.imageView setImageWithURL:[NSURL URLWithString:source.faviconLink]];
        cell.textLabel.text = source.feedInfo.title;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"updated %1.1f seconds ago", -[source.lastUpdatedDate timeIntervalSinceNow]];
    }
    
    return cell;
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

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SRSource *source = nil;
    if (self.likeableFeedItems.count && indexPath.row == 0) {
        source = [SRSource new];
        source.feedItems = [self.likeableFeedItems copy];
    }
    else {
        int index = self.likeableFeedItems.count ? indexPath.row - 1 : indexPath.row;
        source = self.sourceManager.sources[index];
    }
    
    [self.navigationController pushViewController:[[SRSecondaryTableViewController alloc] initWithSource:source] animated:YES];
}

#pragma mark - SRAddSourceViewControllerDelegate methods

- (void)addSourceViewController:(SRAddSourceViewController *)controller didRetrieveSource:(SRSource *)source
{
    [self.sourceManager addSource:source];
    [self.sourceManager saveSources];
    
    [self.tableView reloadData];
}

#pragma mark - UI related

- (void)add
{
    SRAddSourceViewController *addSourceViewController = [SRAddSourceViewController new];
    addSourceViewController.delegate = self;
    
    [self.navigationController presentViewController:addSourceViewController animated:YES completion:nil];
}

- (void)refresh:(id)sender
{
    [self.sourceManager refreshSources];
}

#pragma mark - SRSourceManagerDelegate methods

- (void)didFinishRefreshingAllSourcesWithError:(NSError *)error
{
    [self.tableView reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
    
    [SRTextFilteringManager sharedManager].delegate = self;
    [[SRTextFilteringManager sharedManager] findLikeableFeedItemsFromSources:[SRSourceManager sharedManager].sources];
}

#pragma mark - SRTextFilteringManagerDelegate methods

- (void)didFinishFindingLikeableFeedItems:(NSArray *)feedItems
{
    DebugLog(@"Found these likeable items: %@", feedItems);
    
    self.likeableFeedItems = [feedItems copy];
    
    if (self.likeableFeedItems.count) {
        UILocalNotification *notification = [UILocalNotification new];
        notification.alertBody = [NSString stringWithFormat:@"Found %d items you might like!", self.likeableFeedItems.count];
        notification.fireDate = [NSDate date];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    
    [self.tableView reloadData];
}

@end
