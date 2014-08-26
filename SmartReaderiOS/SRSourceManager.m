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
#import "MWFeedInfo.h"

#define kSourcesFileName @"sources.bin"

@interface SRSourceManager () <SRSourceDelegate>
{
    BOOL _workInProgress;
}

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
        self.sources = [temp copy];
    }
}

- (void)deleteSources
{
    DebugLog(@"Deleting all sources...");
    
    [[SRFileUtility sharedUtility] removeDocumentFile:kSourcesFileName];
}

- (void)deleteSourceAtIndex:(NSInteger)index
{
    DebugLog(@"Deleting source at index: %lu, source: %@", (long)index, self.sources[index]);
    
    NSMutableArray *sourcesCopy = [self.sources mutableCopy];
    [sourcesCopy removeObjectAtIndex:index];
    self.sources = [sourcesCopy copy];
    
    [self saveSources];
}

- (void)saveSources
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[NSKeyedArchiver archivedDataWithRootObject:self.sources] writeToFile:[[SRFileUtility sharedUtility] documentPathForFile:kSourcesFileName] atomically:YES];
        
        DebugLog(@"Saving sources... Source file size is: %1.4f MB.", [[[SRFileUtility sharedUtility] documentSizeForFile:kSourcesFileName] floatValue] / (1024 * 1024));
    });
}

- (void)refreshSources
{
    if (!self.sources.count) {
        [self.mainDelegate didFinishRefreshingAllSourcesWithError:nil];
        return;
    }
    
    if (_workInProgress) {
        DebugLog(@"Already refreshing sources...");
        return;
    }
    
    _workInProgress = YES;
    
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
    
    self.sources = [self.sources sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        SRSource *source1 = (SRSource *)obj1;
        SRSource *source2 = (SRSource *)obj2;
        return [source1.feedInfo.title compare:source2.feedInfo.title];
    }];
}

#pragma mark - SRSourceDelegate

- (void)didFinishRefreshingSource:(SRSource *)source withError:(NSError *)error
{    
    static int sourcesUpdated = 0;
    sourcesUpdated++;
    if (sourcesUpdated == self.sources.count) {
        _workInProgress = NO;
        
        sourcesUpdated = 0;
        
        [self saveSources];
        
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
            [self.backgroundDelegate didFinishRefreshingAllSourcesWithError:nil];
        }
        else {
            [self.mainDelegate didFinishRefreshingAllSourcesWithError:nil];
        }
    }
}

@end
