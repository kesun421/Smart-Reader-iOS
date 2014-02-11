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

#define IMAGE_SIZE CGSizeMake(25.0, 25.0)

@interface SRSecondaryTableViewController () <SRMainContentViewControllerDelegate, UIGestureRecognizerDelegate>
{
    BOOL _markedAllAsRead;
}

@property (nonatomic) SRSource *source;
@property (nonatomic, copy) NSArray *feedItems;

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
                                                                      action:@selector(dismiss)];
        self.navigationItem.leftBarButtonItem = backButton;
        
        if (self.source.sourceForInterestingItems) {
            self.navigationItem.title = @"Suggested Reading...";
            
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
    
    if (!self.source.sourceForBookmarkedItems && !self.source.sourceForInterestingItems) {
        self.tableView.separatorColor = [UIColor colorWithRed:240.0f/255.0f green:240.0f/255.0f blue:240.0f/255.0f alpha:1.0];
        
        //Add a left swipe gesture recognizer
        UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                         action:@selector(handleSwipeLeft:)];
        [recognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
        [self.tableView addGestureRecognizer:recognizer];
    }
    
    self.tableView.separatorColor = [UIColor colorWithRed:240.0f/255.0f green:240.0f/255.0f blue:240.0f/255.0f alpha:1.0];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"tick-7.png"] resizeImageToSize:IMAGE_SIZE]
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(markAll:)];
    
    _markedAllAsRead = NO;
    
    BOOL allRead = YES;
    for (MWFeedItem *feedItem in self.feedItems) {
        allRead = allRead && feedItem.read;
    }
    
    if (allRead) {
        _markedAllAsRead = YES;
        self.navigationItem.rightBarButtonItem.image = [[UIImage imageNamed:@"tick-7-active.png"] resizeImageToSize:IMAGE_SIZE];
    }
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

- (void)dismiss
{
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    MWFeedItem *feedItem = self.feedItems[indexPath.row];
    
    cell.textLabel.text = feedItem.title;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    
    if (self.source.sourceForInterestingItems || self.source.sourceForBookmarkedItems) {
        NSMutableAttributedString *detailText = [NSMutableAttributedString new];
        
        NSMutableAttributedString *sourceTitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", feedItem.source.feedInfo.title]
                                                                                        attributes:@{
                                                                                              NSFontAttributeName : [UIFont boldSystemFontOfSize:12.0],
                                                                                              }];
        
        NSMutableAttributedString *feedSummary = [[NSMutableAttributedString alloc] initWithString:[feedItem.summary stringByConvertingHTMLToPlainText]
                                                                                        attributes:@{
                                                                                              NSFontAttributeName : [UIFont systemFontOfSize:12.0],
                                                                                              }];
        
        [detailText appendAttributedString:sourceTitle];
        [detailText appendAttributedString:feedSummary];
        
        cell.detailTextLabel.attributedText = detailText;
        cell.detailTextLabel.numberOfLines = 4;
    }
    else {
        cell.detailTextLabel.text = [feedItem.summary stringByConvertingHTMLToPlainText];
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
    if ([feedItem.summary stringByConvertingHTMLToPlainText].length) {
        if (self.source.sourceForInterestingItems || self.source.sourceForBookmarkedItems) {
            return 95.0;
        }
        else {
            return 80.0;
        }
    }
    else {
        return 44.0;
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
        self.feedItems = [SRTextFilteringManager sharedManager].likableFeedItems;
    }
    
    [self.tableView reloadData];
}

#pragma mark - Feed item methods

- (void)markAll:(id)sender
{
    if (!_markedAllAsRead) {
        _markedAllAsRead = YES;
        
        self.navigationItem.rightBarButtonItem.image = [[UIImage imageNamed:@"tick-7-active.png"] resizeImageToSize:IMAGE_SIZE];
        
        [self.source.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                    MWFeedItem *feedItem = (MWFeedItem *)obj;
                                                    feedItem.read = YES;
                                                }];
    }
    else {
        _markedAllAsRead = NO;
        
        self.navigationItem.rightBarButtonItem.image = [[UIImage imageNamed:@"tick-7.png"] resizeImageToSize:IMAGE_SIZE];
        
        [self.source.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                    MWFeedItem *feedItem = (MWFeedItem *)obj;
                                                    feedItem.read = NO;
                                                }];
        
        self.feedItems = self.source.feedItems;
    }
    
    
    NSString *message = _markedAllAsRead ? @"Marked all as read" : @"Marked all as unread";
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithMessage:message];
    [self.navigationController.view addSubview:msgController.view];
    [msgController animate];
    
    [[SRSourceManager sharedManager] saveSources];
    
    [self.tableView reloadData];
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
}

@end
