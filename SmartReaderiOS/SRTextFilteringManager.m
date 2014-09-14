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

@interface SRTextFilteringManager ()

@property (nonatomic) NSDictionary *interestedFeedItemTokens;

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
    self.interestedFeedItemTokens = [NSKeyedUnarchiver unarchiveObjectWithFile:[[SRFileUtility sharedUtility] documentPathForFile:kLikedFeedItemTokensFileName]];
    
    if (!self.interestedFeedItemTokens) {
        self.interestedFeedItemTokens = [NSDictionary new];
    }
}

- (void)saveTokens
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        DebugLog(@"Saving liked feed item tokens...");
        
        [[NSKeyedArchiver archivedDataWithRootObject:self.interestedFeedItemTokens] writeToFile:[[SRFileUtility sharedUtility] documentPathForFile:kLikedFeedItemTokensFileName] atomically:YES];
    });
}

- (void)processFeedItemAsLiked:(MWFeedItem *)feedItem
{
    if (!feedItem.tokens.count) {
        return;
    }
    
    feedItem.userLiked = YES;
    
    NSMutableDictionary *dictCopy = [self.interestedFeedItemTokens mutableCopy];
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
    
    self.interestedFeedItemTokens = [dictCopy copy];
    DebugLog(@"Liked feed items tokens: %@", self.interestedFeedItemTokens);
    
    [self saveTokens];
    
    [[SRSourceManager sharedManager] saveSources];
}

- (void)findInterestingFeedItemsFromSources:(NSArray *)sources
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [sources enumerateObjectsWithOptions:NSEnumerationConcurrent
                                  usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                      SRSource *source = (SRSource *)obj;
                                      
                                      [source.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                                         usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                                             MWFeedItem *feedItem = (MWFeedItem *)obj;
                                                                             
                                                                             if (!feedItem.tokens.count || feedItem.userLiked) {
                                                                                 DebugLog(@"Skipped the processing of feed item: %@. No tokens: %@. User liked: %@.", feedItem, !feedItem.tokens.count ? @"YES" : @"NO",feedItem.userLiked ? @"YES" : @"NO");
                                                                                 return;
                                                                             }
                                                                             
                                                                             float _interestingProbability = 0.0;
                                                                             int tokenCount = 0;
                                                                             for (NSString *token in feedItem.tokens.allKeys) {
                                                                                 if (_interestedFeedItemTokens[token]) {
                                                                                     _interestingProbability += log([_interestedFeedItemTokens[token] floatValue] / _interestedFeedItemTokens.count);
                                                                                     tokenCount++;
                                                                                 }
                                                                             }
                                                                             
                                                                             // There is no value of continuing since a comparison can not be made from existing data.
                                                                             if (_interestingProbability == 0.0) {
                                                                                 return;
                                                                             }
                                                                             
                                                                             _interestingProbability *= -1.0;
                                                                             
                                                                             DebugLog(@"Feed item: %@, with link: %@, has interesting probability: %f, calculated using %d token(s).", feedItem, feedItem.link, _interestingProbability, tokenCount);
                                                                             
                                                                             feedItem.interestingProbability = _interestingProbability;
                                                                         }];
                                  }];
        
        // Find all the news items that are marked as likable by algorithm, but not marked as unlikable by the user.
        NSMutableArray *feedItems = [NSMutableArray new];
        
        int totalFeedItemsCount = 0;
        for (SRSource *source in sources) {
            totalFeedItemsCount += source.feedItems.count;
            for (MWFeedItem *feedItem in source.feedItems) {
                // Only show those items that were liked by the algorithm.
                if (feedItem.interestingProbability != 0.0 && !feedItem.userLiked && !feedItem.read) {
                    feedItem.source = source;
                    [feedItems addObject:feedItem];
                }
            }
        }
        
        // Sort the likable feed items by their likable probability in descending order.
        [feedItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            MWFeedItem *feedItem1 = (MWFeedItem *)obj1;
            MWFeedItem *feedItem2 = (MWFeedItem *)obj2;
            
            if (feedItem1.interestingProbability < feedItem2.interestingProbability) {
                return (NSComparisonResult)NSOrderedDescending;
            } else if(feedItem1.interestingProbability > feedItem2.interestingProbability) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }];
        
        // Only show as much as 20 percent of the total feed items.
        int likableFeedItemsLimit = floorf(totalFeedItemsCount * 0.2);
        
        if (_interestingArticlesCap == 0) {
            _interestingArticlesCap = 25;
        }
        
        if (likableFeedItemsLimit > _interestingArticlesCap) {
            likableFeedItemsLimit = _interestingArticlesCap;
        }
        
        if (feedItems.count > likableFeedItemsLimit) {
            self.interestingFeedItems = [feedItems subarrayWithRange:NSMakeRange(0, likableFeedItemsLimit)];
        }
        else {
            self.interestingFeedItems = [feedItems copy];
        }
        
        // Call to delegate on main thread to refresh with suggested news items.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate didFinishFindinglikableFeedItems];
        });
    });
}

@end
