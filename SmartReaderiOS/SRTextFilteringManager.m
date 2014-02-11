//
//  SRTextFilteringManager.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 12/31/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import "SRTextFilteringManager.h"
#import "MWFeedItem.h"
#import "SRSource.h"
#import "SRSourceManager.h"
#import "SRFileUtility.h"
#import "NSString+HTML.h"
#import "AFHTTPRequestOperationManager.h"
#import "HTMLNode.h"
#import "HTMLParser.h"

#define kLikedFeedItemTokensFileName @"liked.bin"
#define kUnlikedFeedItemTokensFileName @"unliked.bin"

@interface SRTextFilteringManager ()

@property (nonatomic) NSDictionary *likedFeedItemTokens;

@end

@implementation SRTextFilteringManager

+ (instancetype)sharedManager
{
    static SRTextFilteringManager *_sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [SRTextFilteringManager new];
        [_sharedManager loadTokens];
    });
    
    return _sharedManager;
}

- (void)loadTokens
{
    self.likedFeedItemTokens = [NSKeyedUnarchiver unarchiveObjectWithFile:[[SRFileUtility sharedUtility] documentPathForFile:kLikedFeedItemTokensFileName]];
    
    if (!self.likedFeedItemTokens) {
        self.likedFeedItemTokens = [NSDictionary new];
    }
}

- (void)saveTokens
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        DebugLog(@"Saving liked feed item tokens...");
        
        [[NSKeyedArchiver archivedDataWithRootObject:self.likedFeedItemTokens] writeToFile:[[SRFileUtility sharedUtility] documentPathForFile:kLikedFeedItemTokensFileName] atomically:YES];
    });
}

- (void)processFeedItemAsLiked:(MWFeedItem *)feedItem
{
    if (!feedItem.tokens.count) {
        return;
    }
    
    feedItem.userLiked = YES;
    
    NSMutableDictionary *dictCopy = [self.likedFeedItemTokens mutableCopy];
    if (!dictCopy) {
        dictCopy = [NSMutableDictionary new];
    }
    
    for (NSString *key in feedItem.tokens.allKeys) {
        NSNumber *value = feedItem.tokens[key];
        
        if (dictCopy[key]) {
            NSNumber *count = dictCopy[key];
            dictCopy[key] = [NSNumber numberWithInt:[count intValue] + [value intValue]];
        }
        else {
            dictCopy[key] = [NSNumber numberWithInt:1];
        }
    }
    
    self.likedFeedItemTokens = [dictCopy copy];
    DebugLog(@"Liked feed items tokens: %@", self.likedFeedItemTokens);
    
    [self saveTokens];
    
    [[SRSourceManager sharedManager] saveSources];
}

- (void)findlikableFeedItemsFromSources:(NSArray *)sources
{
    [sources enumerateObjectsWithOptions:NSEnumerationConcurrent
                              usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                  SRSource *source = (SRSource *)obj;
                                  
                                  [source.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                                     usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                                         MWFeedItem *feedItem = (MWFeedItem *)obj;
                                                                         
                                                                         feedItem.like = NO;
                                                                         
                                                                         if (!feedItem.tokens.count || feedItem.userLiked) {
                                                                             DebugLog(@"Skipped the processing of feed item: %@. No tokens: %@. User liked: %@.", feedItem, !feedItem.tokens.count ? @"YES" : @"NO",feedItem.userLiked ? @"YES" : @"NO");
                                                                             return;
                                                                         }
                                                                         
                                                                         float likableProbability = 0.0;
                                                                         for (NSString *token in feedItem.tokens.allKeys) {
                                                                             if (_likedFeedItemTokens[token]) {
                                                                                 likableProbability += log([_likedFeedItemTokens[token] floatValue] / _likedFeedItemTokens.count);
                                                                             }
                                                                         }
                                                                         
                                                                         // There is no value of continuing since a comparison can not be made from existing data.
                                                                         if (likableProbability == 0.0) {
                                                                             return;
                                                                         }
                                                                         
                                                                         likableProbability *= -1.0;
                                                                         
                                                                         DebugLog(@"Feed item: %@, with link: %@, has likable probability: %f", feedItem, feedItem.link, likableProbability);
                                                                         
                                                                         feedItem.likableProbability = likableProbability;
                                                                     }];
                              }];
    
    // Find all the news items that are marked as likable by algorithm, but not marked as unlikable by the user.
    NSMutableArray *feedItems = [NSMutableArray new];
    
    int totalFeedItemsCount = 0;
    for (SRSource *source in sources) {
        totalFeedItemsCount += source.feedItems.count;
        for (MWFeedItem *feedItem in source.feedItems) {
            // Only show those items that were liked by the algorithm.
            if (feedItem.likableProbability != 0.0 && !feedItem.userLiked && !feedItem.read) {
                feedItem.source = source;
                [feedItems addObject:feedItem];
            }
        }
    }
    
    // Sort the likable feed items by their likable probability in descending order.
    [feedItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        MWFeedItem *feedItem1 = (MWFeedItem *)obj1;
        MWFeedItem *feedItem2 = (MWFeedItem *)obj2;
        
        if (feedItem1.likableProbability < feedItem2.likableProbability) {
            return (NSComparisonResult)NSOrderedDescending;
        } else if(feedItem1.likableProbability > feedItem2.likableProbability) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    // Only show as much as 10 percent of the total feed items.
    int likableFeedItemsLimit = floorf(totalFeedItemsCount * 0.1);
    
    if (likableFeedItemsLimit > 25) {
        likableFeedItemsLimit = 25;
    }
    
    if (feedItems.count > likableFeedItemsLimit) {
        self.likableFeedItems = [feedItems subarrayWithRange:NSMakeRange(0, likableFeedItemsLimit)];
        
        NSArray *leftOverItems = [feedItems subarrayWithRange:NSMakeRange(likableFeedItemsLimit, feedItems.count - likableFeedItemsLimit)];
        [leftOverItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                        usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                            MWFeedItem *feedItem = (MWFeedItem *)obj;
                                            feedItem.like = NO;
                                        }];
    }
    else {
        self.likableFeedItems = [feedItems copy];
    }
    
    // Call to delegate to refresh with suggested news items.
    [self.delegate didFinishFindinglikableFeedItems];
}

@end
