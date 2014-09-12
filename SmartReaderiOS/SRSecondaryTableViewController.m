//
//  SRSecondaryTableViewController.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/25/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import "SRSecondaryTableViewController.h"
#import "SRMainContentViewController.h"
#import "SRSource.h"
#import "MWFeedInfo.h"
#import "MWFeedItem.h"
#import "NSString+HTML.h"
#import "UIImage+Extensions.h"
#import "SRMessageViewController.h"
#import "SRSourceManager.h"
#import "SRTextFilteringManager.h"
#import "UIImage+Extensions.h"
#import "SRFeedItemSpeechPlayer.h"
#import "SRTableViewCell.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

#define IMAGE_SIZE CGSizeMake(25.0, 25.0)

@interface SRSecondaryTableViewController () <SRMainContentViewControllerDelegate, SRFeedItemSpeechPlayerDelegate, UIGestureRecognizerDelegate>
{
    BOOL _markedAllAsRead;
    BOOL _playing;
}

@property (nonatomic) SRSource *source;
@property (nonatomic, copy) NSArray *feedItems;

@property (nonatomic) UIBarButtonItem *markAllButton;
@property (nonatomic) UIBarButtonItem *playButton;

@property (nonatomic) UIFont *cronosProBoldFont;
@property (nonatomic) UIFont *cronosProRegularFont;

@property (nonatomic) UIFont *calibriBoldFont;
@property (nonatomic) UIFont *calibriFont;

@property (nonatomic, copy) NSIndexPath *indexPathOfFeedItemBeingRead;

- (void)refresh:(id)sender;
- (void)markAll:(id)sender;
- (void)playAll:(id)sender;

@end

@implementation SRSecondaryTableViewController

- (instancetype)initWithSource:(SRSource *)source
{
    self = [super init];
    if (self) {
        self.source = source;
        
        // Customize the back button.
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"backward-7.png"] resizeImageToSize:IMAGE_SIZE]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(dismiss:)];
        
        self.navigationItem.leftBarButtonItem = backButton;
        
        if (self.source.sourceForInterestingItems) {
            self.navigationItem.title = @"Interesting Articles...";
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(refresh:)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:nil];
        }
        else if (self.source.sourceForBookmarkedItems) {
            self.navigationItem.title = @"Bookmarked Items";
        }
        else {
            self.navigationItem.title = self.source.feedInfo.title;
        }
        
        if (self.source.sourceForBookmarkedItems) {
            self.feedItems = source.feedItems;
        }
        else {
            // Only show the unread items.
            NSMutableArray *temp = [NSMutableArray new];
            for (MWFeedItem *feedItem in source.feedItems) {
                if (!feedItem.read) {
                    [temp addObject:feedItem];
                }
            }
            
            self.feedItems = [temp copy];
        }
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    UISwipeGestureRecognizer *swipeToGoBack = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
    [self.view addGestureRecognizer:swipeToGoBack];
    
    if (!self.source.sourceForBookmarkedItems) {
        // Add a left swipe gesture recognizer for marking items as read.
        UISwipeGestureRecognizer *swipeToMarkAsRead = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                                action:@selector(handleSwipeLeft:)];
        swipeToMarkAsRead.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.tableView addGestureRecognizer:swipeToMarkAsRead];
        
        // Add a left swipe gesture recognizer for bookmarking items.
        UISwipeGestureRecognizer *swipeToBookmark = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                                action:@selector(handleSwipeRight:)];
        swipeToBookmark.direction = UISwipeGestureRecognizerDirectionRight;
        [self.tableView addGestureRecognizer:swipeToBookmark];
    }
    
    self.tableView.separatorColor = [UIColor clearColor];
    
    self.cronosProRegularFont = [UIFont fontWithName:@"CronosPro-Regular" size:14];
    self.cronosProBoldFont = [UIFont fontWithName:@"CronosPro-Bold" size:14];
    
    self.calibriBoldFont = [UIFont fontWithName:@"Calibri-Bold" size:14];
    self.calibriFont = [UIFont fontWithName:@"Calibri" size:14];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.markAllButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"tick-7.png"] resizeImageToSize:IMAGE_SIZE]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(markAll:)];
    
    self.playButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"button-play-7.png"] resizeImageToSize:IMAGE_SIZE]
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(playAll:)];
    
    self.navigationItem.rightBarButtonItems = @[ self.markAllButton, self.playButton ];
    
    _markedAllAsRead = NO;
    
    BOOL allRead = YES;
    for (MWFeedItem *feedItem in self.feedItems) {
        allRead = allRead && feedItem.read;
    }
    
    if (allRead) {
        _markedAllAsRead = YES;
        self.markAllButton.image = [[UIImage imageNamed:@"tick-7-active.png"] resizeImageToSize:IMAGE_SIZE];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Setup screen name tracking in GA.
    NSString *screenTitle;
    if (self.source.sourceForBookmarkedItems) {
        screenTitle = @"Bookmarked Items";
    }
    else if (self.source.sourceForInterestingItems) {
        screenTitle = @"Interesting Items";
    }
    else {
        screenTitle = @"Feed Item";
    }
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:[NSString stringWithFormat:@"%@ - %@", NSStringFromClass([self class]), screenTitle]];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
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

- (void)dismiss:(id)sender
{
    // If the swipe gesture triggered the dismiss action, make sure it was from within 120 px of the view, and a swipe to right.
    // This is for mimicking the standard swipe gesture behavior that belongs to the standard back button.
    if ([sender isKindOfClass:[UISwipeGestureRecognizer class]]) {
        UISwipeGestureRecognizer * swipeGestureRecognizer = (UISwipeGestureRecognizer *)sender;
        if (!([swipeGestureRecognizer locationInView:self.view].x < 120 && swipeGestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight)) {
            return;
        }
    }
    
    if (_playing) {        
        [[SRFeedItemSpeechPlayer sharedInstance] stop];
        
        _playing = NO;
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.feedItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    SRTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[SRTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    MWFeedItem *feedItem = self.feedItems[indexPath.row];
    
    cell.textLabel.text = feedItem.title;
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.font = [self.calibriBoldFont fontWithSize:18];
    cell.detailTextLabel.font = [self.calibriFont fontWithSize:15];
    
    if ([indexPath compare:self.indexPathOfFeedItemBeingRead] != NSOrderedSame) {
        cell.backgroundColor = nil;
    }
    else {
        cell.backgroundColor = [UIColor colorWithRed:201/255.0f green:226/255.0f blue:255/255.0f alpha:1.0f];
    }
    
    if (self.source.sourceForInterestingItems || self.source.sourceForBookmarkedItems) {
        NSMutableAttributedString *detailText = [NSMutableAttributedString new];
        
        NSMutableAttributedString *sourceTitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", feedItem.source.feedInfo.title]
                                                                                        attributes:@{
                                                                                              NSFontAttributeName : [self.calibriBoldFont fontWithSize:15.0],
                                                                                              }];
        
        NSMutableAttributedString *feedSummary = [[NSMutableAttributedString alloc] initWithString:feedItem.summary.length ? feedItem.summary : feedItem.content
                                                                                        attributes:@{
                                                                                              NSFontAttributeName : [self.calibriFont fontWithSize:15.0],
                                                                                              }];
        
        [detailText appendAttributedString:sourceTitle];
        [detailText appendAttributedString:feedSummary];
        
        cell.detailTextLabel.attributedText = detailText;
        cell.detailTextLabel.numberOfLines = 4;
    }
    else {
        cell.detailTextLabel.text = feedItem.summary;
        cell.detailTextLabel.numberOfLines = 3;
    }

    if (feedItem.read) {
        cell.textLabel.textColor = [UIColor colorWithRed:180.0f/255.0f green:180.0f/255.0f blue:180.0f/255.0f alpha:1.0];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:190.0f/255.0f green:190.0f/255.0f blue:190.0f/255.0f alpha:1.0];
    }
    else {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor grayColor];
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.alpha = 0.0;
    [UIView animateWithDuration:0.75 animations:^{
        cell.alpha = 1.0;
    }];
}

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MWFeedItem *feedItem = self.feedItems[indexPath.row];
    SRMainContentViewController *mainContentViewController = [[SRMainContentViewController alloc] initWithFeedItem:feedItem];
    mainContentViewController.delegate = self;
    [self.navigationController pushViewController:mainContentViewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MWFeedItem *feedItem = self.feedItems[indexPath.row];
    if (feedItem.summary.length) {
        if (self.source.sourceForInterestingItems || self.source.sourceForBookmarkedItems) {
            return UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? 125.0 : 115.0;
        }
        else {
            return UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? 115 : 105.0;
        }
    }
    else {
        return UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? 88.0 : 58.0;
    }
}

#pragma mark - SRMainContentViewControllerDelegate methods

- (void)refresh:(id)sender
{
    if (self.source.sourceForBookmarkedItems) {
        NSMutableArray *bookMarkedItems = [NSMutableArray new];
        for (MWFeedItem *feedItem in self.feedItems) {
            if (feedItem.bookmarked) {
                [bookMarkedItems addObject:feedItem];
            }
        }
        
        self.feedItems = [bookMarkedItems copy];
    }
    
    if (self.source.sourceForInterestingItems) {
        self.feedItems = [SRTextFilteringManager sharedManager].interestingFeedItems;
    }
    
    [self.tableView reloadData];
}

#pragma mark - SRFeedItemSpeechPlayerDelegate methods

- (void)playingFeedItemAtIndex:(NSIndexPath *)indexPath
{
    self.indexPathOfFeedItemBeingRead = indexPath;
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithRed:201/255.0f green:226/255.0f blue:255/255.0f alpha:1.0f];
}


- (void)finishedPlayingFeedItemAtIndex:(NSIndexPath *)indexPath
{
    self.indexPathOfFeedItemBeingRead = nil;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = nil;
}

- (void)finishedPlayingAllFeedItems
{
    self.playButton.image = [[UIImage imageNamed:@"button-play-7.png"] resizeImageToSize:IMAGE_SIZE];
}

#pragma mark - Feed item methods

- (void)markAll:(id)sender
{
    if (!_markedAllAsRead) {
        _markedAllAsRead = YES;
        
        self.markAllButton.image = [[UIImage imageNamed:@"tick-7-active.png"] resizeImageToSize:IMAGE_SIZE];
        
        [self.source.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                    MWFeedItem *feedItem = (MWFeedItem *)obj;
                                                    feedItem.read = YES;
                                                }];
    }
    else {
        _markedAllAsRead = NO;
        
        self.markAllButton.image = [[UIImage imageNamed:@"tick-7.png"] resizeImageToSize:IMAGE_SIZE];
        
        [self.source.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                    MWFeedItem *feedItem = (MWFeedItem *)obj;
                                                    feedItem.read = NO;
                                                }];
        
        self.feedItems = self.source.feedItems;
    }
    
    
    NSString *message = _markedAllAsRead ? @"Marked all as read" : @"Marked all as unread";
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithMessage:message];
    [msgController animateInView:self.navigationController.view];
    
    [[SRSourceManager sharedManager] saveSources];
    
    [self.tableView reloadData];
    
    // Send event to GA.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                          action:@"mark_all_button_press"
                                                           label:_markedAllAsRead ? @"Marked all as read" : @"Marked all as unread"
                                                           value:nil] build]];
}

- (void)playAll:(id)sender
{
    NSString *message = _playing ? @"Stopped reading" : @"Started reading summary";
    
    if (!_playing) {
        _playing = YES;
        self.playButton.image = [[UIImage imageNamed:@"button-play-7-active.png"] resizeImageToSize:IMAGE_SIZE];
        
        [SRFeedItemSpeechPlayer sharedInstance].feedItems = self.feedItems;
        [SRFeedItemSpeechPlayer sharedInstance].delegate = self;
        [[SRFeedItemSpeechPlayer sharedInstance] play];
    }
    else {
        _playing = NO;
        self.playButton.image = [[UIImage imageNamed:@"button-play-7.png"] resizeImageToSize:IMAGE_SIZE];
        
        [[SRFeedItemSpeechPlayer sharedInstance] stop];
    }
    
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithMessage:message];
    [msgController animateInView:self.navigationController.view];
    
    // Send event to GA.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"
                                                          action:@"play_all_button_press"
                                                           label:_playing ? @"Stopped reading" : @"Started reading"
                                                           value:nil] build]];
}

#pragma mark - Swipe gesture

- (void)handleSwipeLeft:(UISwipeGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    
    MWFeedItem *feedItem = (MWFeedItem *)self.feedItems[indexPath.row];
    feedItem.read = YES;
    
    NSMutableArray *unreadFeedItems = [self.feedItems mutableCopy];
    [unreadFeedItems removeObjectAtIndex:indexPath.row];
    self.feedItems = [unreadFeedItems copy];
    
    [self.tableView endUpdates];
    
    [[SRSourceManager sharedManager] saveSources];
    
    DebugLog(@"Marked as read by swipping left...");
}

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.tableView];
    
    // Make sure that the swipe gesture does not conflict with the gesture to signal the view to go back.
    if (location.x < self.tableView.center.x) {
        [self dismiss:gestureRecognizer];
        return;
    }
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
    
    MWFeedItem *feedItem = (MWFeedItem *)self.feedItems[indexPath.row];
    feedItem.read = YES;
    feedItem.bookmarked = YES;
    feedItem.bookmarkedDate = [NSDate date];
    
    NSMutableArray *feedItems = [self.feedItems mutableCopy];
    [feedItems removeObjectAtIndex:indexPath.row];
    self.feedItems = [feedItems copy];
    
    [self.tableView endUpdates];
    
    [[SRSourceManager sharedManager] saveSources];
    
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithMessage:@"Bookmarked"];
    [msgController animateInView:self.navigationController.view];
    
    DebugLog(@"Bookmarked by swipping right...");
}

@end
