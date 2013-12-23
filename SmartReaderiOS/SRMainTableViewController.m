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

#define kSourcesFileName @"sources.plist"

@interface SRMainTableViewController () <SRAddSourceViewControllerDelegate>

/** List of feed sources. */
@property (nonatomic) NSMutableArray *sources;

@end

@implementation SRMainTableViewController

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
    
    self.sources = [NSMutableArray new];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    // Return the number of rows in the section.
    return self.sources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    SRSource *source = self.sources[indexPath.row];
    
    [cell.imageView setImageWithURL:[NSURL URLWithString:source.faviconLink]];
    cell.textLabel.text = source.feedInfo.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%f seconds ago", -[source.lastUpdatedDate timeIntervalSinceNow]];
    
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
    [self.navigationController pushViewController:[[SRSecondaryTableViewController alloc] initWithSource:self.sources[indexPath.row]] animated:YES];
}

#pragma mark - SRAddSourceViewControllerDelegate methods

- (void)addSourceViewController:(SRAddSourceViewController *)controller didRetrieveSource:(SRSource *)source
{
    [self.sources addObject:source];
    [self.tableView reloadData];
}

- (void)dismissAddSourceViewController:(SRAddSourceViewController *)controller
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UI related

- (void)add
{
    SRAddSourceViewController *addSourceViewController = [SRAddSourceViewController new];
    addSourceViewController.delegate = self;
    
    [self.navigationController presentViewController:addSourceViewController animated:YES completion:nil];
}

#pragma mark - Save/delete news sources

/**
 Tries to add what the url is pointing to as a news source.  If url points to feed, add the url as news source.  If url points to web page, parse web page for feed url, then add feed url as news source.  Return YES if news source added successfully.  If url points to neither feed nor web site with feed, return NO.
 */
- (BOOL)add:(NSURL *)url
{
    return YES;
}

/**
 Saves the news source list to disk.  If saved successfully, return YES, else return NO.
 */
- (BOOL)save
{
    return [self.sources writeToFile:[[SRFileUtility sharedUtility] documentPathForFile:kSourcesFileName] atomically:YES];
}

/**
 Read the news source list from disk.  If read successfully, return YES, else return NO.
 */
- (BOOL)readSources
{
    NSArray *temp = [NSArray arrayWithContentsOfFile:[[SRFileUtility sharedUtility] documentPathForFile:kSourcesFileName]];
    
    if (temp) {
        self.sources = temp;
        return YES;
    }
    else {
        return NO;
    }
}

/**
 Removes the news source list from disk.  If deletion is successful, return YES, else return NO.
 */
- (BOOL)delete
{
    return [[SRFileUtility sharedUtility] removeDocumentFile:kSourcesFileName];
}

@end
