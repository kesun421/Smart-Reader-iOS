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
#import "SRSplashScreenViewController.h"
#import "SRAddSourceViewController.h"
#import "SRMessageViewController.h"
#import "SRSource.h"
#import "SRSourceManager.h"
#import "SRTextFilteringManager.h"
#import "MWFeedInfo.h"
#import "MWFeedParser.h"
#import "MWFeedInfo.h"
#import "MWFeedItem.h"
#import "UIImage+Extensions.h"
#import "UIViewController+CWPopup.h"
#import "AFNetworkReachabilityManager.h"
#import "UIImageView+AFNetworking.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"


#define IMAGE_SIZE CGSizeMake(25.0, 25.0)

@interface SRMainTableViewController () <UIGestureRecognizerDelegate, SRAddSourceViewControllerDelegate, SRSourceManagerDelegate, SRTextFilteringManagerDelegate, SRSecondaryTableViewControllerDelegate>

@property (nonatomic) UIFont *cronosProBoldFont;
@property (nonatomic) UIFont *cronosProRegularFont;

@property (nonatomic) UIFont *calibriBoldFont;
@property (nonatomic) UIFont *calibriFont;

@property (nonatomic) SRMessageViewController *messageViewController;

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.tableView.separatorColor = [UIColor clearColor];
    
    self.cronosProRegularFont = [UIFont fontWithName:@"CronosPro-Regular" size:14];
    self.cronosProBoldFont = [UIFont fontWithName:@"CronosPro-Bold" size:14];
    
    self.calibriBoldFont = [UIFont fontWithName:@"Calibri-Bold" size:14];
    self.calibriFont = [UIFont fontWithName:@"Calibri" size:14];
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self action:@selector(refreshSources) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"plus-circle-7.png"] resizeImageToSize:IMAGE_SIZE]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(add)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"book-7.png"] resizeImageToSize:IMAGE_SIZE]
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(showBookmarks)];

    if (![SRTextFilteringManager sharedManager].interestingFeedItems.count && !self.refreshControl.refreshing) {
        self.messageViewController = [[SRMessageViewController alloc] initWithParentView:self.navigationController.view message:@"Pull list down to refresh"];
        [self.messageViewController show];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Setup screen name tracking in GA.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:NSStringFromClass([self class])];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    // Setup reachability detection.
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusNotReachable || status == AFNetworkReachabilityStatusUnknown) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Unreachable" message:@"Smart Reader can not connect to the network, so app functions will be limited until network connection is reestablished." delegate:nil cancelButtonTitle:@"Cool, got it" otherButtonTitles:nil];
            [alert show];
        }
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    // Register for notifications for the app.  Doing it here so the pop up won't interfere with the launch screen.
    UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI methods

- (void)add
{
    SRAddSourceViewController *addSourceViewController = [SRAddSourceViewController new];
    addSourceViewController.delegate = self;
    
    // Disable the access to the UI in the background.
    self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.view.userInteractionEnabled = NO;
    
    [self.navigationController presentPopupViewController:addSourceViewController animated:YES completion:nil];
}

- (void)refreshSources
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl beginRefreshing];
    });
    
    [[SRSourceManager sharedManager] refreshSources];
    
    // Send event to GA.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                          action:@"pull_to_refresh"
                                                           label:@"Refresh sources"
                                                           value:nil] build]];
}

- (void)showBookmarks
{
    SRSource *source = [SRSource new];
    source.sourceForBookmarkedItems = YES;
    NSMutableArray *bookmarkedItems = [NSMutableArray new];
    
    for (SRSource *src in [SRSourceManager sharedManager].sources) {
        for (MWFeedItem *feedItem in src.feedItems) {
            if (feedItem.bookmarked) {
                feedItem.source = src;
                [bookmarkedItems addObject:feedItem];
            }
        }
    }
    
    [bookmarkedItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        MWFeedItem *feedItem1 = (MWFeedItem *)obj1;
        MWFeedItem *feedItem2 = (MWFeedItem *)obj2;
        
        return [feedItem2.bookmarkedDate compare:feedItem1.bookmarkedDate];
    }];
    
    source.feedItems = [bookmarkedItems copy];
    
    SRSecondaryTableViewController *secondaryViewController = [[SRSecondaryTableViewController alloc] initWithSource:source];
    secondaryViewController.delegate = self;
    
    [self.navigationController pushViewController:secondaryViewController animated:YES];
}

- (void)startEdit:(id)sender
{
    if (self.tableView.editing) {
        return;
    }
    
    [self.tableView setEditing:YES animated:YES];
    
    self.messageViewController = [[SRMessageViewController alloc] initWithParentView:self.navigationController.view message:@"Tap any news item to end editing"];
    [self.messageViewController show];
    
    // Send event to GA.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                          action:@"hold_to_edit"
                                                           label:@"Edit sources"
                                                           value:nil] build]];
}

- (void)endEdit:(id)sender
{
    if (!self.tableView.editing) {
        return;
    }
    
    [self.tableView setEditing:NO animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [SRTextFilteringManager sharedManager].interestingFeedItems.count ? [SRSourceManager sharedManager].sources.count + 1 : [SRSourceManager sharedManager].sources.count;
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
    cell.textLabel.font = [self.calibriFont fontWithSize:titleFontSize];
    cell.backgroundColor = [UIColor whiteColor];
    
    // Add rounded corner to favicons.
    cell.imageView.layer.cornerRadius = 5.0;
    cell.imageView.clipsToBounds = YES;
    
    CGSize newImageSize = CGSizeMake(30.0, 30.0);
    
    if ([SRTextFilteringManager sharedManager].interestingFeedItems.count && indexPath.row == 0) {
        int count = 0;
        for (MWFeedItem *feedItem in [SRTextFilteringManager sharedManager].interestingFeedItems) {
            if (!feedItem.read) {
                count++;
            }
        }
        
        cell.imageView.image = [[[UIImage imageNamed:@"star-7.png"] resizeImageToSize:newImageSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.textLabel.text = @"Interesting Articles...";
        cell.textLabel.font = [self.calibriBoldFont fontWithSize:titleFontSize];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d unread", count];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
            rotationAnimation.duration = 1.0;
            [cell.imageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
        });
    }
    else {
        long index = [SRTextFilteringManager sharedManager].interestingFeedItems.count ? indexPath.row - 1 : indexPath.row;
        SRSource *source = [SRSourceManager sharedManager].sources[index];
        
        int count = 0;
        for (MWFeedItem *feedItem in source.feedItems) {
            if (!feedItem.read) {
                count++;
            }
        }
        
        __weak UITableViewCell *weakCell = cell;
        UIImage *placeholderImage = [[[UIImage imageNamed:@"rss-7.png"] resizeImageToSize:newImageSize] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [cell.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:source.faviconLink]]
                              placeholderImage:placeholderImage
                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                           weakCell.imageView.image = [image resizeImageToSize:newImageSize];
                                       }
                                       failure:nil];

        cell.textLabel.text = source.feedInfo.title;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d unread", count];
        
        // Add long hold gesture recognizer to enable editing (deleting and moving) of table view cells.
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(startEdit:)];
        [longPressGestureRecognizer setMinimumPressDuration:1.0];
        [cell addGestureRecognizer:longPressGestureRecognizer];
        
        // Add tap gesture recognizer to disable editing of table view cells.
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEdit:)];
        tapGestureRecognizer.delegate = self;
        [tapGestureRecognizer setNumberOfTapsRequired:1];
        [cell addGestureRecognizer:tapGestureRecognizer];
    }
    
    cell.detailTextLabel.font = self.calibriFont;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if ([SRTextFilteringManager sharedManager].interestingFeedItems.count && indexPath.row == 0) {
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
        NSInteger index = [SRTextFilteringManager sharedManager].interestingFeedItems.count ? indexPath.row - 1 : indexPath.row;
        [[SRSourceManager sharedManager] deleteSourceAtIndex:index];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if ([SRTextFilteringManager sharedManager].interestingFeedItems.count) {
        fromIndexPath = [NSIndexPath indexPathForRow:fromIndexPath.row - 1 inSection:fromIndexPath.section];
        toIndexPath = [NSIndexPath indexPathForRow:toIndexPath.row - 1 inSection:toIndexPath.section];
    }
    
    NSMutableArray *sources = (NSMutableArray *)[[SRSourceManager sharedManager].sources mutableCopy];
    SRSource *source = sources[fromIndexPath.row];
    
    [sources removeObject:source];
    [sources insertObject:source atIndex:toIndexPath.row];
    
    [SRSourceManager sharedManager].sources = sources;
    [[SRSourceManager sharedManager] saveSources];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if ([SRTextFilteringManager sharedManager].interestingFeedItems.count && indexPath.row == 0) {
        return NO;
    }
    else {
        return YES;
    }
}

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SRSource *source = nil;
    if ([SRTextFilteringManager sharedManager].interestingFeedItems.count && indexPath.row == 0) {
        source = [SRSource new];
        source.feedItems = [SRTextFilteringManager sharedManager].interestingFeedItems;
        source.sourceForInterestingItems = YES;
    }
    else {
        long index = [SRTextFilteringManager sharedManager].interestingFeedItems.count ? indexPath.row - 1 : indexPath.row;
        source = [SRSourceManager sharedManager].sources[index];
    }
    
    SRSecondaryTableViewController *secondaryViewController = [[SRSecondaryTableViewController alloc] initWithSource:source];
    secondaryViewController.delegate = self;
    
    [self.navigationController pushViewController:secondaryViewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0;
}

#pragma mark - SRAddSourceViewControllerDelegate methods

- (void)addSourceViewController:(SRAddSourceViewController *)controller didRetrieveSource:(SRSource *)source
{
    [[SRSourceManager sharedManager] addSource:source];
    [[SRSourceManager sharedManager] saveSources];
    
    [self.tableView reloadData];
    
    // Send event to GA.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"app_action"
                                                          action:@"source_added"
                                                           label:@"Source added"
                                                           value:nil] build]];
}

- (void)addSourceViewControllerDidFinishAddingAllSources:(SRAddSourceViewController *)controller
{
    self.messageViewController = [[SRMessageViewController alloc] initWithParentView:self.navigationController.view message:@"News source added"];
    [self.messageViewController show];
}

- (void)addSourceViewController:(SRAddSourceViewController *)controller failedToRetrieveSourceWithURL:(NSString *)url
{
    // Send event to GA.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"app_action"
                                                          action:@"source_add_failed"
                                                           label:[NSString stringWithFormat:@"Source add failed for url: %@", url]
                                                           value:nil] build]];
}

- (void)addSourceViewControllerDidDismiss
{
    // Enable the access to the UI that was in the background of the popup view.
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.view.userInteractionEnabled = YES;
    
    [self.navigationController dismissPopupViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // Make sure the tap gesture recognizer is only used when the table is in editing mode.  This will prevent the tap gesture recognizer from
    // hijacking the default tap behavior for the table view cells.
    if (![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return YES;
    }
    
    if (self.tableView.editing) {
        return YES;
    }
    
    return NO;
}

#pragma mark - SRSourceManagerDelegate methods

- (void)didFinishRefreshingAllSourcesWithError:(NSError *)error
{
    [self.tableView reloadData];
    
    [SRTextFilteringManager sharedManager].delegate = self;
    [[SRTextFilteringManager sharedManager] findInterestingFeedItemsFromSources:[SRSourceManager sharedManager].sources];
}

#pragma mark - SRTextFilteringManagerDelegate methods

- (void)didFinishFindinglikableFeedItems
{
    DebugLog(@"Found these likable items: %@", [SRTextFilteringManager sharedManager].interestingFeedItems);
    
    if ([SRTextFilteringManager sharedManager].interestingFeedItems.count) {
        self.messageViewController = [[SRMessageViewController alloc] initWithParentView:self.navigationController.view
                                                                                 message:[NSString stringWithFormat:@"Found %lu interesting articles",(unsigned long)[SRTextFilteringManager sharedManager].interestingFeedItems.count]];
        [self.messageViewController show];
    }
    else {
        self.messageViewController = [[SRMessageViewController alloc] initWithParentView:self.navigationController.view message:@"Train me using ☆ in article view"];
        [self.messageViewController show];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl endRefreshing];
    });
    
    [self.tableView reloadData];
    
    // Send event to GA.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"app_action"
                                                          action:@"finished_finding_likeable_feed_items"
                                                           label:@"Finished finding likeable feed items"
                                                           value:nil] build]];
}

#pragma mark - SRSecondaryTableViewControllerDelegate methods

- (void)refresh:(id)sender
{
    [self.tableView reloadData];
}

@end
