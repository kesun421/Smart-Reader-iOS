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
#import "UIImage+Extensions.h"
#import "SRMessageViewController.h"

@interface SRMainTableViewController () <SRAddSourceViewControllerDelegate, SRSourceManagerDelegate, SRTextFilteringManagerDelegate, SRSecondaryTableViewControllerDelegate>
{
    BOOL _refreshingSourcesTableCellAnimationSwitch;
}

@property (nonatomic) NSArray *likeableFeedItems;

@end

@implementation SRMainTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    [[SRSourceManager sharedManager] loadSources];
    [SRSourceManager sharedManager].mainDelegate = self;
    
    [self refreshSources:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSources:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshSources:) forControlEvents:UIControlEventValueChanged];
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
    return self.likeableFeedItems.count ? [SRSourceManager sharedManager].sources.count + 1 : [SRSourceManager sharedManager].sources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Set back to default.
    float titleFontSize = 18.0;
    cell.textLabel.font = [UIFont systemFontOfSize:titleFontSize];
    cell.backgroundColor = [UIColor whiteColor];
    
    // Add rounded corner to favicons.
    cell.imageView.layer.cornerRadius = 5.0;
    cell.imageView.clipsToBounds = YES;
    
    CGSize newImageSize = CGSizeMake(30.0, 30.0);
    
    if (self.likeableFeedItems.count && indexPath.row == 0) {
        int count = 0;
        for (MWFeedItem *feedItem in self.likeableFeedItems) {
            if (!feedItem.read) {
                count++;
            }
        }
        
        cell.imageView.image = [[[UIImage imageNamed:@"star.png"] resizeImageToSize:newImageSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.textLabel.text = @"Suggested Reading...";
        cell.textLabel.font = [UIFont boldSystemFontOfSize:titleFontSize];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d unread", count];
        cell.backgroundColor = [UIColor colorWithRed:238.0f/255.0f green:247.0f/255.0f blue:255.0f/255.0f alpha:1.0];
        
        if (_refreshingSourcesTableCellAnimationSwitch) {
            CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
            rotationAnimation.duration = 1.0;
            [cell.imageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
            
            _refreshingSourcesTableCellAnimationSwitch = NO;
        }
    }
    else {
        long index = self.likeableFeedItems.count ? indexPath.row - 1 : indexPath.row;
        SRSource *source = [SRSourceManager sharedManager].sources[index];
        
        int count = 0;
        for (MWFeedItem *feedItem in source.feedItems) {
            if (!feedItem.read) {
                count++;
            }
        }
        
        __weak UITableViewCell *weakCell = cell;
        UIImage *placeholderImage = [[[UIImage imageNamed:@"166-newspaper.png"] resizeImageToSize:newImageSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [cell.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:source.faviconLink]]
                              placeholderImage:placeholderImage
                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                           weakCell.imageView.image = [image resizeImageToSize:newImageSize];
                                       }
                                       failure:nil];

        cell.textLabel.text = source.feedInfo.title;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d unread", count];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if (self.likeableFeedItems.count && indexPath.row == 0) {
        return NO;
    }
    else {
        return YES;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSInteger index = self.likeableFeedItems.count ? indexPath.row - 1 : indexPath.row;
        [[SRSourceManager sharedManager] deleteSourceAtIndex:index];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

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
    // Stop the refresh control from continued spinning.  If we don't do this, it's possible that we navigated to another view controller
    // while the refresh control was spinning, when we navigate back to the main cview controller, there will be a gap left in the UI that
    // used to hold the refresh control.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
    
    SRSource *source = nil;
    if (self.likeableFeedItems.count && indexPath.row == 0) {
        source = [SRSource new];
        source.feedItems = [self.likeableFeedItems copy];
        source.sourceForInterestingItems = YES;
    }
    else {
        long index = self.likeableFeedItems.count ? indexPath.row - 1 : indexPath.row;
        source = [SRSourceManager sharedManager].sources[index];
    }
    
    SRSecondaryTableViewController *secondaryViewController = [[SRSecondaryTableViewController alloc] initWithSource:source];
    secondaryViewController.delegate = self;
    
    [self.navigationController pushViewController:secondaryViewController animated:YES];
}

#pragma mark - SRAddSourceViewControllerDelegate methods

- (void)addSourceViewController:(SRAddSourceViewController *)controller didRetrieveSource:(SRSource *)source
{
    [[SRSourceManager sharedManager] addSource:source];
    [[SRSourceManager sharedManager] saveSources];
    
    [self.tableView reloadData];
}

- (void)addSourceViewControllerDidFinishAddingAllSources:(SRAddSourceViewController *)controller
{
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithSize:CGSizeMake(210.0, 60.0) message:@"News source added!"];
    [self.navigationController.view addSubview:msgController.view];
    [msgController animate];
}

#pragma mark - UI related

- (void)add
{
    SRAddSourceViewController *addSourceViewController = [SRAddSourceViewController new];
    addSourceViewController.delegate = self;
    
    [self.navigationController presentViewController:addSourceViewController animated:YES completion:nil];
}

- (void)refreshSources:(id)sender
{
    _refreshingSourcesTableCellAnimationSwitch = YES;
    
    [[SRSourceManager sharedManager] refreshSources];
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
        // A toast message about found likeable items.
        SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithSize:CGSizeMake(250.0, 60.0) message:[NSString stringWithFormat:@"Found %d interesting items!", self.likeableFeedItems.count]];
        [self.navigationController.view addSubview:msgController.view];
        [msgController animate];
    }
    
    [self.tableView reloadData];
}

#pragma mark - SRSecondaryTableViewControllerDelegate methods

- (void)refresh:(id)sender
{
    [self.tableView reloadData];
}

@end
