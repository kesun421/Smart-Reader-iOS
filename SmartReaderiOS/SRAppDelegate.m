//
//  SRAppDelegate.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/25/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import "SRAppDelegate.h"
#import "SRSplashScreenViewController.h"
#import "SRMainTableViewController.h"
#import "SRNavigationController.h"
#import "SRSourceManager.h"
#import "SRSource.h"
#import "MWFeedItem.h"
#import "SRTextFilteringManager.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"

typedef void(^BackgroundFetchBlock)(UIBackgroundFetchResult);

@interface SRAppDelegate () <SRSourceManagerDelegate, SRTextFilteringManagerDelegate>
{
    BackgroundFetchBlock backgroundFetchResultBlock;
    BOOL _showUnreadCount;
}

@end

@implementation SRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIView appearance] setTintColor:[UIColor grayColor]];
    
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[SRNavigationController alloc] initWithRootViewController:[SRSplashScreenViewController new]];
    [self.window makeKeyAndVisible];
    
    // Register app setting defaults. Settings value are applied in applicationDidBecomeActive.
    NSDictionary *appSettings = @{
                                  @"feedUpdateFrequency" : @(2),
                                  @"interestingArticlesCap" : @(25),
                                  @"iconBadgeCount" : @"Interesting Articles",
                                  };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:appSettings];
    
    // Setup Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].dispatchInterval = 20;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelError];
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-54476627-1"];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // The initial request for allowing notifications is in the main table view view controller.
    UIUserNotificationSettings* notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    if (notificationSettings.types | UIUserNotificationTypeBadge) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: _showUnreadCount ? [self totalUnreadCount] : [self totalInterestingUnreadCount]];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // Apply app settings values.
    NSNumber *feedUpdateFrequency = (NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"feedUpdateFrequency"];
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:60 * 60 * feedUpdateFrequency.intValue];
    
    NSNumber *interestingArticlesCap = (NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:@"interestingArticlesCap"];
    [SRTextFilteringManager sharedManager].interestingArticlesCap = interestingArticlesCap.intValue;
    
    NSString *iconBadgeCount = (NSString *)[[NSUserDefaults standardUserDefaults] valueForKey:@"iconBadgeCount"];
    _showUnreadCount = [iconBadgeCount isEqualToString:@"Unread Articles"];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (int)totalUnreadCount
{
    int totalUnreadCount = 0;
    
    for (SRSource *source in [SRSourceManager sharedManager].sources) {
        for (MWFeedItem *item in source.feedItems) {
            if (!item.read) {
                totalUnreadCount += 1;
            }
        }
    }
    
    return totalUnreadCount;
}

- (int)totalInterestingUnreadCount
{
    int totalInterestingUnreadCount = 0;
    
    for (MWFeedItem *item in [SRTextFilteringManager sharedManager].interestingFeedItems) {
        if (!item.read) {
            totalInterestingUnreadCount += 1;
        }
    }
    
    return totalInterestingUnreadCount;
}


#pragma mark - Background fetch

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    backgroundFetchResultBlock = completionHandler;
    
    if (![SRSourceManager sharedManager].sources.count) {
        [[SRSourceManager sharedManager] loadSources];
    }
    
    [SRSourceManager sharedManager].backgroundDelegate = self;
    [[SRSourceManager sharedManager] refreshSources];
}

#pragma mark - SRSourceManagerDelegate methods

- (void)didFinishRefreshingAllSourcesWithError:(NSError *)error
{
    [SRTextFilteringManager sharedManager].delegate = self;
    [[SRTextFilteringManager sharedManager] findInterestingFeedItemsFromSources:[SRSourceManager sharedManager].sources];
    
    // Send event to GA.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"app_action"
                                                          action:@"background_finished_refreshing_all_sources"
                                                           label:@"Background finished refreshing all sources"
                                                           value:nil] build]];

}

#pragma mark - SRTextFilteringManagerDelegate methods

- (void)didFinishFindinglikableFeedItems
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = [SRTextFilteringManager sharedManager].interestingFeedItems.count;
    
    NSString *message = nil;
    
    int totalUnreadCount = [self totalUnreadCount];
    
    if (totalUnreadCount != 0 && [SRTextFilteringManager sharedManager].interestingFeedItems.count == 0) {
        message = [NSString stringWithFormat:@"Added %d new articles!", totalUnreadCount];
    }
    else if (totalUnreadCount != 0 && [SRTextFilteringManager sharedManager].interestingFeedItems.count != 0){
        message = [NSString stringWithFormat:@"Added %d new articles! %lu are interesting...", totalUnreadCount, (unsigned long)[SRTextFilteringManager sharedManager].interestingFeedItems.count];
    }
    
    if (totalUnreadCount || [SRTextFilteringManager sharedManager].interestingFeedItems.count) {
        [[SRSourceManager sharedManager] saveSources];
    }
    
    if (message.length) {
        UILocalNotification *notification = [UILocalNotification new];
        notification.alertBody = message;
        notification.fireDate = [NSDate date];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        
        backgroundFetchResultBlock(UIBackgroundFetchResultNewData);
        
        DebugLog(@"Background fetch completed with new articles count: %d, and interesting articles count: %lu", totalUnreadCount, (unsigned long)[SRTextFilteringManager sharedManager].interestingFeedItems.count);
    }
    else {
        backgroundFetchResultBlock(UIBackgroundFetchResultNoData);
        
        DebugLog(@"Background fetch completed with no new articles...  Interesting articles count: %lu", (unsigned long)[SRTextFilteringManager sharedManager].interestingFeedItems.count);
    }
    
    // Send event to GA.
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"app_action"
                                                          action:@"background_finished_finding_likeable_feed_items"
                                                           label:@"Background finished finding likeable feed items"
                                                           value:nil] build]];
}

@end
