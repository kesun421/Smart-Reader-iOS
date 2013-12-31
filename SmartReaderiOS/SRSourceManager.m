//
//  SRSourceManager.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 12/27/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import "SRSourceManager.h"
#import "SRSource.h"
#import "SRFileUtility.h"
#import "MWFeedItem.h"

#define kSourcesFileName @"sources.bin"

@interface SRSourceManager () <SRSourceDelegate>
@end

@implementation SRSourceManager

+ (instancetype)sharedManager
{
    static SRSourceManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedManager = [SRSourceManager new];
    });
    
    return _sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.sources = [NSArray new];
    }
    return self;
}

- (void)loadSources
{
    DebugLog(@"Loading sources... Source file size is: %1.4f MB.", [[[SRFileUtility sharedUtility] documentSizeForFile:kSourcesFileName] floatValue] / (1024 * 1024));
    
    NSArray *temp = [NSKeyedUnarchiver unarchiveObjectWithFile:[[SRFileUtility sharedUtility] documentPathForFile:kSourcesFileName]];
    
    if (temp) {
        self.sources = temp;
    }
}

- (void)deleteSources
{
    DebugLog(@"Deleting sources...");
    
    [[SRFileUtility sharedUtility] removeDocumentFile:kSourcesFileName];
}

- (void)saveSources
{
    [[NSKeyedArchiver archivedDataWithRootObject:self.sources] writeToFile:[[SRFileUtility sharedUtility] documentPathForFile:kSourcesFileName] atomically:YES];
    
    DebugLog(@"Saving sources... Source file size is: %1.4f MB.", [[[SRFileUtility sharedUtility] documentSizeForFile:kSourcesFileName] floatValue] / (1024 * 1024));
}

- (void)refreshSources
{
    DebugLog(@"Refreshing sources...");
    
    for (SRSource *source in self.sources) {
        source.delegate = self;
        [source refresh];
    }
}

- (void)addSource:(SRSource *)source
{
    DebugLog(@"Adding new source...");
    
    self.sources = [self.sources arrayByAddingObject:source];
}

#pragma mark - SRSourceDelegate

- (void)didFinishRefreshingSource:(SRSource *)source withError:(NSError *)error
{
    // [source removeOldFeedItems];
    
    static int sourcesUpdated = 0;
    sourcesUpdated++;
    if (sourcesUpdated == self.sources.count) {
        sourcesUpdated = 0;
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
            [self.backgroundDelegate didFinishRefreshingAllSourcesWithError:nil];
        }
        else {
            [self.mainDelegate didFinishRefreshingAllSourcesWithError:nil];
        }
    }
    
    if (!error) {
        [self saveSources];
    }
}

@end
