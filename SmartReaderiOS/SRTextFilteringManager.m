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
    NSString *readabilityUrl = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", feedItem.link];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:readabilityUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *htmlString = operation.responseString;
        
        HTMLParser *parser = [[HTMLParser alloc] initWithString:htmlString error:nil];
        if (parser.body) {
            NSMutableDictionary *dictCopy = liked ? [self.likedFeedItemTokens mutableCopy] : [self.unlikedFeedItemTokens mutableCopy];
            
            for (HTMLNode *node in[parser.body findChildTags:@"p"]) {
                NSString *content = [[node allContents] stringByConvertingHTMLToPlainText];
                NSArray *tokens = [content componentsSeparatedByString:@" "];
                
                for (NSString *token in tokens) {
                    NSString *tokenCopy = [token copy];
                    
                    // Remove from tokens, the characters that does not contribute too much meaning.
                    tokenCopy = [tokenCopy stringByReplacingOccurrencesOfString:@"(" withString:@""];
                    tokenCopy = [tokenCopy stringByReplacingOccurrencesOfString:@")" withString:@""];
                    tokenCopy = [tokenCopy stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    
                    // Only consider the tokens that are between 3 to 44 characters long.
                    if (tokenCopy.length <= 3 || tokenCopy.length >= 44) {
                        continue;
                    }
                    
                    // If token already exists in the dict, increment the token count.  Else, add the new token with count of 1.
                    if (dictCopy[tokenCopy]) {
                        NSNumber *count = dictCopy[tokenCopy];
                        dictCopy[tokenCopy] = [NSNumber numberWithInt:[count intValue] + 1];
                    }
                    else {
                        dictCopy[tokenCopy] = [NSNumber numberWithInt:1];
                    }
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
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

- (NSArray *)findLikeableFeedItemsFromSources:(NSArray *)sources
{
    __block NSMutableArray *likeableFeedItems = [NSMutableArray new];
    
    [sources enumerateObjectsWithOptions:NSEnumerationConcurrent
                              usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                  SRSource *source = (SRSource *)obj;
                                  [source.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                                     usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                                         MWFeedItem *feedItem = (MWFeedItem *)obj;
                                                                         
                                                                         NSString *readabilityUrl = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", feedItem.link];
                                                                         
                                                                         AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
                                                                         manager.responseSerializer = [AFHTTPResponseSerializer serializer];
                                                                         [manager GET:readabilityUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                             NSString *htmlString = operation.responseString;
                                                                             
                                                                             HTMLParser *parser = [[HTMLParser alloc] initWithString:htmlString error:nil];
                                                                             if (parser.body) {
                                                                                 NSMutableDictionary *tokenDict = [NSMutableDictionary new];
                                                                                 
                                                                                 for (HTMLNode *node in[parser.body findChildTags:@"p"]) {
                                                                                     NSString *content = [[node allContents] stringByConvertingHTMLToPlainText];
                                                                                     NSArray *tokens = [content componentsSeparatedByString:@" "];
                                                                                     
                                                                                     for (NSString *token in tokens) {
                                                                                         NSString *tokenCopy = [token copy];
                                                                                         
                                                                                         // Remove from tokens, the characters that does not contribute too much meaning.
                                                                                         tokenCopy = [tokenCopy stringByReplacingOccurrencesOfString:@"(" withString:@""];
                                                                                         tokenCopy = [tokenCopy stringByReplacingOccurrencesOfString:@")" withString:@""];
                                                                                         tokenCopy = [tokenCopy stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                                                                                         
                                                                                         // Only consider the tokens that are between 3 to 44 characters long.
                                                                                         if (tokenCopy.length <= 3 || tokenCopy.length >= 44) {
                                                                                             continue;
                                                                                         }
                                                                                         
                                                                                         // If token already exists in the dict, increment the token count.  Else, add the new token with count of 1.
                                                                                         if (tokenDict[tokenCopy]) {
                                                                                             NSNumber *count = tokenDict[tokenCopy];
                                                                                             tokenDict[tokenCopy] = [NSNumber numberWithInt:[count intValue] + 1];
                                                                                         }
                                                                                         else {
                                                                                             tokenDict[tokenCopy] = [NSNumber numberWithInt:1];
                                                                                         }
                                                                                     }
                                                                                 }
                                                                                 
                                                                                 // Sort the keys in order of largest value, so the keys with the highest values are placed first.
                                                                                 NSArray *sortedKeys = [tokenDict keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                                     return -[(NSNumber *)obj1 compare:(NSNumber *)obj2];
                                                                                 }];
                                                                                 
                                                                                 // Only take the first 15 tokens for use.
                                                                                 if (sortedKeys.count > 15) {
                                                                                     sortedKeys = [sortedKeys subarrayWithRange:NSMakeRange(0, 15)];
                                                                                 }
                                                                                 
                                                                                 DebugLog(@"Token dict: %@", tokenDict);
                                                                                 
                                                                                 DebugLog(@"Sorted token dict keys: %@", sortedKeys);
                                                                                 
                                                                                 // Take dict and do Bayesian text filtering...
                                                                                 [likeableFeedItems addObject:feedItem];
                                                                             }
                                                                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                             
                                                                         }];
                                                                     }];
                              }];
    
    return likeableFeedItems;
}

@end
