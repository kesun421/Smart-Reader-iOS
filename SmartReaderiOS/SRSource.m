//
//  SRSource.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/26/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import "SRSource.h"
#import "MWFeedInfo.h"
#import "MWFeedItem.h"
#import "MWFeedParser.h"
#import "HTMLNode.h"
#import "HTMLParser.h"
#import "AFHTTPRequestOperationManager.h"
#import "NSString+HTML.h"

@interface SRSource () <MWFeedParserDelegate>

@end

@implementation SRSource

- (instancetype)init
{
    if (self = [super init]) {
        self.uuid = [[NSUUID UUID] UUIDString];
        self.feedItems = [NSArray array];
    }
    return self;
}

#pragma mark - NScoding

- (void)addFeedItem:(MWFeedItem *)feedItem
{
    NSMutableArray *tempArray = [self.feedItems mutableCopy];
    [tempArray addObject:feedItem];
    self.feedItems = [tempArray copy];
}

- (void)refresh
{
    MWFeedParser *feedParser = [[MWFeedParser alloc] initWithFeedURL:[NSURL URLWithString:self.feedLink]];
    feedParser.delegate = self;
    feedParser.feedParseType = ParseTypeFull;
    feedParser.connectionType = ConnectionTypeAsynchronously;
    [feedParser parse];
}

- (void)removeOldFeedItems
{
    NSMutableArray *tempArray = [self.feedItems mutableCopy];
    
    for (MWFeedItem *feedItem in self.feedItems) {
        if ([feedItem.date timeIntervalSinceNow] < -60 * 60 * 24 * 30 && !feedItem.bookmarked) {
            [tempArray removeObject:feedItem];
        }
    }
    
    self.feedItems = [tempArray copy];
}

- (void)parseFeedItemTokens
{
    [self.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                     usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                         MWFeedItem *feedItem = (MWFeedItem *)obj;
                                         if ((!feedItem.content.length && !feedItem.summary.length) || feedItem.tokens.count) {
                                             return;
                                         }
                                         
                                         NSMutableDictionary *dictCopy = feedItem.tokens ? [feedItem.tokens mutableCopy] : [NSMutableDictionary new];
                                         NSString *content = feedItem.content.length ? [feedItem.content stringByConvertingHTMLToPlainText] : [feedItem.summary stringByConvertingHTMLToPlainText];
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
                                         
                                         if (dictCopy.count) {
                                             feedItem.tokens = [dictCopy copy];
                                             DebugLog(@"Finished parsing tokens for feed item: %@", feedItem);
                                         }
                                     }];
}

#pragma mark - MWFeedParserDelegate

- (void)feedParserDidStart:(MWFeedParser *)parser
{
    DebugLog(@"Feed parsing started...");
    
    _newCount = 0;
    _interestingCount = 0;
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info
{
    DebugLog(@"Parsed feed info: %@", info);
    
    self.feedInfo = info;
    self.feedLink = parser.url.absoluteString;
    self.lastUpdatedDate = [NSDate date];
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item
{
    __block BOOL itemExists = NO;
    
    [self.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                     usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                         MWFeedItem *existingItem = (MWFeedItem *)obj;
                                         if ([existingItem.title isEqualToString:item.title] || [existingItem.identifier isEqualToString:item.identifier]) {
                                             itemExists = YES;
                                         }
                                     }];
    
    if (!itemExists) {
        DebugLog(@"Added feed item: %@", item);
        
        [self addFeedItem:item];
        _newCount++;
    }
}

- (void)feedParserDidFinish:(MWFeedParser *)parser
{
    DebugLog(@"Feed parsing ended...");
    
    // Sort the feed items according to their publish date.
    self.feedItems = [self.feedItems sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        MWFeedItem *item1 = (MWFeedItem *)obj1;
        MWFeedItem *item2 = (MWFeedItem *)obj2;
        
        return [item2.date compare:item1.date];
    }];
    
    [self.delegate didFinishRefreshingSource:self withError:nil];
}

- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error
{
    DebugLog(@"Feed parsing failed with error: %@", error);
    
    [self.delegate didFinishRefreshingSource:self withError:error];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.feedInfo = [decoder decodeObjectForKey:@"feedInfo"];
        self.feedItems = [decoder decodeObjectForKey:@"feedItems"];
        self.faviconLink = [decoder decodeObjectForKey:@"faviconLink"];
        self.feedLink = [decoder decodeObjectForKey:@"feedLink"];
        self.lastUpdatedDate = [decoder decodeObjectForKey:@"lastUpdatedDate"];
        self.uuid = [decoder decodeObjectForKey:@"uuid"];
        _newCount = [decoder decodeIntForKey:@"newCount"];
        _interestingCount = [decoder decodeIntForKey:@"interestingCount"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.feedInfo forKey:@"feedInfo"];
    [encoder encodeObject:self.feedItems forKey:@"feedItems"];
    [encoder encodeObject:self.faviconLink forKey:@"faviconLink"];
    [encoder encodeObject:self.feedLink forKey:@"feedLink"];
    [encoder encodeObject:self.lastUpdatedDate forKey:@"lastUpdatedDate"];
    [encoder encodeObject:self.uuid forKey:@"uuid"];
    [encoder encodeInt:self.newCount forKey:@"newCount"];
    [encoder encodeInt:self.interestingCount forKey:@"interestingCount"];
}

@end
