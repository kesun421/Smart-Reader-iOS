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

- (void)findlikableFeedItemsFromSources:(NSArray *)sources
{
    [sources enumerateObjectsWithOptions:NSEnumerationConcurrent
                              usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                  SRSource *source = (SRSource *)obj;
                                  
                                  [source.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                                     usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                                         MWFeedItem *feedItem = (MWFeedItem *)obj;
                                                                         
                                                                         feedItem.like = NO;
                                                                         
                                                                         if (!feedItem.tokens.count || feedItem.userLiked || feedItem.userUnliked) {
                                                                             DebugLog(@"Skipped the processing of feed item: %@. No tokens: %@. User liked: %@. User unliked: %@", feedItem, !feedItem.tokens.count ? @"YES" : @"NO",feedItem.userLiked ? @"YES" : @"NO", feedItem.userUnliked ? @"YES" : @"NO");
                                                                             return;
                                                                         }
                                                                         
                                                                         float likableProbability = 0.0;
                                                                         float unlikableProbability = 0.0;
                                                                         for (NSString *token in feedItem.tokens.allKeys) {
                                                                             if (_likedFeedItemTokens[token]) {
                                                                                 likableProbability += ([_likedFeedItemTokens[token] floatValue] / _likedFeedItemTokens.count);
                                                                             }
                                                                             
                                                                             if (_unlikedFeedItemTokens[token]) {
                                                                                 unlikableProbability += ([_unlikedFeedItemTokens[token] floatValue] / _unlikedFeedItemTokens.count);
                                                                             }
                                                                         }
                                                                         
                                                                         // There is no value of continuing since a comparison can not be made from existing data.
                                                                         if (likableProbability == 0.0 || unlikableProbability == 0.0) {
                                                                             return;
                                                                         }
                                                                         
                                                                         DebugLog(@"Feed item: %@, with link: %@, has likable probability: %f, has unlikable probability: %f", feedItem, feedItem.link, likableProbability, unlikableProbability);
                                                                         
                                                                         likableProbability = likableProbability * _likedFeedItemTokens.count / (_likedFeedItemTokens.count + _unlikedFeedItemTokens.count);
                                                                         
                                                                         unlikableProbability = unlikableProbability * _unlikedFeedItemTokens.count / (_likedFeedItemTokens.count + _unlikedFeedItemTokens.count);
                                                                         
                                                                         if (likableProbability > unlikableProbability) {
                                                                             feedItem.like = YES;
                                                                             feedItem.likableProbability = likableProbability;
                                                                         }
                                                                     }];
                              }];
    
    // Find all the news items that are marked as likable by algorithm, but not marked as unlikable by the user.
    NSMutableArray *feedItems = [NSMutableArray new];
    
    int totalFeedItemsCount = 0;
    for (SRSource *source in sources) {
        totalFeedItemsCount += source.feedItems.count;
        for (MWFeedItem *feedItem in source.feedItems) {
            // Only show those items that were liked by the algorithm.
            if (feedItem.like && !feedItem.userLiked && !feedItem.userUnliked && !feedItem.read) {
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
    
    // Only show as much as 25 items.
    if (feedItems.count > 25) {
        self.likableFeedItems = [feedItems subarrayWithRange:NSMakeRange(0, 25)];
        
        NSArray *leftOverItems = [feedItems subarrayWithRange:NSMakeRange(25, feedItems.count - 25)];
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
