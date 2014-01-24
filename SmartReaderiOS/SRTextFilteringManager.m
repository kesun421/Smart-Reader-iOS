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
@property (nonatomic) NSDictionary *unlikedFeedItemTokens;

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
    
    self.unlikedFeedItemTokens = [NSKeyedUnarchiver unarchiveObjectWithFile:[[SRFileUtility sharedUtility] documentPathForFile:kUnlikedFeedItemTokensFileName]];
    
    if (!self.unlikedFeedItemTokens) {
        self.unlikedFeedItemTokens = [NSDictionary new];
    }
}

- (void)saveTokens
{
    [[NSKeyedArchiver archivedDataWithRootObject:self.likedFeedItemTokens] writeToFile:[[SRFileUtility sharedUtility] documentPathForFile:kLikedFeedItemTokensFileName] atomically:YES];
    
    [[NSKeyedArchiver archivedDataWithRootObject:self.unlikedFeedItemTokens] writeToFile:[[SRFileUtility sharedUtility] documentPathForFile:kUnlikedFeedItemTokensFileName] atomically:YES];
}

- (void)processFeedItem:(MWFeedItem *)feedItem AsLiked:(BOOL)liked
{
    if (!feedItem.tokens.count) {
        return;
    }
    
    feedItem.userLiked = liked;
    feedItem.userUnliked = !liked;
    
    NSMutableDictionary *dictCopy = liked ? [self.likedFeedItemTokens mutableCopy] : [self.unlikedFeedItemTokens mutableCopy];
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
    
    if (liked) {
        self.likedFeedItemTokens = [dictCopy copy];
        DebugLog(@"Liked feed items tokens: %@", self.likedFeedItemTokens);
    }
    else {
        self.unlikedFeedItemTokens = [dictCopy copy];
        DebugLog(@"Unliked feed items tokens: %@", self.unlikedFeedItemTokens);
    }
    
    [self saveTokens];
    
    [[SRSourceManager sharedManager] saveSources];
}

- (void)findLikeableFeedItemsFromSources:(NSArray *)sources
{
    [sources enumerateObjectsWithOptions:NSEnumerationConcurrent
                              usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                  SRSource *source = (SRSource *)obj;
                                  
                                  [source.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                                     usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                                         MWFeedItem *feedItem = (MWFeedItem *)obj;
                                                                         
                                                                         // Sort the keys in order of largest value, so the keys with the highest values are placed first.
                                                                         NSArray *sortedKeys = [feedItem.tokens keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                             return -[(NSNumber *)obj1 compare:(NSNumber *)obj2];
                                                                         }];
                                                                         
                                                                         if (!sortedKeys.count) {
                                                                             return;
                                                                         }
                                                                         
                                                                         // Only take the first 15 tokens for use.
                                                                         if (sortedKeys.count > 15) {
                                                                             sortedKeys = [sortedKeys subarrayWithRange:NSMakeRange(0, 15)];
                                                                         }
                                                                         
                                                                         float likeableProbability = 1.0;
                                                                         float unlikeableProbability = 1.0;
                                                                         for (NSString *token in sortedKeys) {
                                                                             if (_likedFeedItemTokens[token]) {
                                                                                 likeableProbability = likeableProbability * ([_likedFeedItemTokens[token] floatValue] / _likedFeedItemTokens.count);
                                                                             }
                                                                             
                                                                             if (_unlikedFeedItemTokens[token]) {
                                                                                 unlikeableProbability = unlikeableProbability * ([_unlikedFeedItemTokens[token] floatValue] / _unlikedFeedItemTokens.count);
                                                                             }
                                                                         }
                                                                         
                                                                         // There is no value of continuing since a comparison can not be made from existing data.
                                                                         if (likeableProbability == 1.0 || unlikeableProbability == 1.0) {
                                                                             return;
                                                                         }
                                                                         
                                                                         likeableProbability = likeableProbability * _likedFeedItemTokens.count / (_likedFeedItemTokens.count + _unlikedFeedItemTokens.count);
                                                                         
                                                                         unlikeableProbability = unlikeableProbability * _unlikedFeedItemTokens.count / (_likedFeedItemTokens.count + _unlikedFeedItemTokens.count);
                                                                         
                                                                         DebugLog(@"Feed item: %@, with link: %@, has likeable probability: %f, has unlikeable probability: %f", feedItem, feedItem.link, log(likeableProbability), log(unlikeableProbability));
                                                                         
                                                                         if (log(likeableProbability) > log(unlikeableProbability)) {
                                                                             feedItem.like = YES;
                                                                             feedItem.likeableProbability = log(likeableProbability);
                                                                         }
                                                                         else {
                                                                             feedItem.like = NO;
                                                                         }
                                                                     }];
                              }];
    
    // Find all the news items that are marked as likeable by algorithm, but not marked as unlikeable by the user.
    NSMutableArray *likeableFeedItems = [NSMutableArray new];
    
    int totalFeedItemsCount = 0;
    for (SRSource *source in sources) {
        for (MWFeedItem *feedItem in source.feedItems) {
            // Only show those items that were liked by the algorithm.
            if (feedItem.like && !feedItem.userLiked && !feedItem.userUnliked && !feedItem.read) {
                feedItem.source = source;
                [likeableFeedItems addObject:feedItem];
            }
            
            totalFeedItemsCount++;
        }
    }
    
    // Sort the likeable feed items by their likeable probability...
    [likeableFeedItems sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        MWFeedItem *feedItem1 = (MWFeedItem *)obj1;
        MWFeedItem *feedItem2 = (MWFeedItem *)obj2;
        
        return feedItem2.likeableProbability > feedItem1.likeableProbability;
    }];
    
    // Only show as much as 10 percent of the total items.
    int tenPercentCount = floorf(totalFeedItemsCount / 10);
    NSArray *topTenPercentItems = likeableFeedItems.count > tenPercentCount ? [likeableFeedItems subarrayWithRange:NSMakeRange(0, floorf(totalFeedItemsCount / 10))] : [likeableFeedItems copy];
    
    // Call to delegate to refresh with suggested news items.
    [self.delegate didFinishFindingLikeableFeedItems:topTenPercentItems];
}

@end
