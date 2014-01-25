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

#define IMAGE_SIZE CGSizeMake(22.0, 22.0)

@interface SRSecondaryTableViewController () <SRMainContentViewControllerDelegate>
{
    BOOL _markedAllAsRead;
}

@property (nonatomic) SRSource *source;
@property (nonatomic, copy) NSArray *ureadFeedItems;

@end

@implementation SRSecondaryTableViewController

- (instancetype)initWithSource:(SRSource *)source
{
    self = [super init];
    if (self) {
        self.source = source;
        self.navigationItem.title = self.source.sourceForInterestingItems ? @"Suggested Reading..." : self.source.feedInfo.title;
        
        // Only show the unread items.
        NSMutableArray *temp = [NSMutableArray new];
        for (MWFeedItem *feedItem in source.feedItems) {
            if (!feedItem.read) {
                [temp addObject:feedItem];
            }
        }
        
        self.ureadFeedItems = [temp copy];
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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"mark-read.png"] resizeImageToSize:IMAGE_SIZE]
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(markAll:)];
    
    if (!self.ureadFeedItems.count) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _markedAllAsRead = NO;
    
    [self.delegate refresh:self];
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
    return self.ureadFeedItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    MWFeedItem *feedItem = self.ureadFeedItems[indexPath.row];
    
    cell.textLabel.text = feedItem.title;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    
    if (self.source.sourceForInterestingItems) {
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
        UIColor *lightGrayColor = [UIColor colorWithRed:204.0f/255.0f green:204.0f/255.0f blue:204.0f/255.0f alpha:1.0];
        cell.textLabel.textColor = lightGrayColor;
        cell.detailTextLabel.textColor = lightGrayColor;
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
    MWFeedItem *feedItem = self.ureadFeedItems[indexPath.row];
    SRMainContentViewController *mainContentViewController = [[SRMainContentViewController alloc] initWithFeedItem:feedItem];
    mainContentViewController.delegate = self;
    [self.navigationController pushViewController:mainContentViewController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MWFeedItem *feedItem = self.ureadFeedItems[indexPath.row];
    if ([feedItem.summary stringByConvertingHTMLToPlainText].length) {
        if (self.source.sourceForInterestingItems) {
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
    [self.tableView reloadData];
}

#pragma mark - Feed item methods

- (void)markAll:(id)sender
{
    if (!_markedAllAsRead) {
        _markedAllAsRead = YES;
        
        self.navigationItem.rightBarButtonItem.image = [[UIImage imageNamed:@"mark-unread.png"] resizeImageToSize:IMAGE_SIZE];
        
        [self.source.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                    MWFeedItem *feedItem = (MWFeedItem *)obj;
                                                    feedItem.read = YES;
                                                }];
    }
    else {
        _markedAllAsRead = NO;
        
        self.navigationItem.rightBarButtonItem.image = [[UIImage imageNamed:@"mark-read.png"] resizeImageToSize:IMAGE_SIZE];
        
        [self.source.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                    MWFeedItem *feedItem = (MWFeedItem *)obj;
                                                    feedItem.read = NO;
                                                }];
    }
    
    NSString *message = _markedAllAsRead ? @"Marked all as read..." : @"Marked all as unread...";
    SRMessageViewController *msgController = [[SRMessageViewController alloc] initWithMessage:message];
    [self.navigationController.view addSubview:msgController.view];
    [msgController animate];
    
    [[SRSourceManager sharedManager] saveSources];
    
    [self.tableView reloadData];
}

@end
