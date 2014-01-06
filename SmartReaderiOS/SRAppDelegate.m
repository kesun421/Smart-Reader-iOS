//
//  SRAppDelegate.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/25/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import "SRAppDelegate.h"
#import "SRMainTableViewController.h"
#import "SRSourceManager.h"
#import "SRSource.h"

typedef void(^BackgroundFetchBlock)(UIBackgroundFetchResult);

@interface SRAppDelegate () <SRSourceManagerDelegate>
{
    BackgroundFetchBlock backgroundFetchResultBlock;
}

@end

@implementation SRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:15 * 60];
    
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[SRMainTableViewController new]];
    [self.window makeKeyAndVisible];
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
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
    int totalNewCount = 0;
    for (SRSource *source in [SRSourceManager sharedManager].sources) {
        totalNewCount += source.newCount;
    }
    
    if (totalNewCount != 0) {
        UILocalNotification *notification = [UILocalNotification new];
        notification.alertBody = [NSString stringWithFormat:@"%d new items for reading!", totalNewCount];
        notification.fireDate = [NSDate date];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        
        backgroundFetchResultBlock(UIBackgroundFetchResultNewData);
    }
    else {
        backgroundFetchResultBlock(UIBackgroundFetchResultNoData);
    }
    
}

@end
