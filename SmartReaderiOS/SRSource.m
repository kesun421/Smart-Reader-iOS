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

@interface SRSource () <MWFeedParserDelegate>

@end

@implementation SRSource

- (instancetype)init
{
    if (self = [super init]) {
        self.uuid = [[NSUUID UUID] UUIDString];
    }
    return self;
}

#pragma mark - NScoding

- (void)addFeedItem:(MWFeedItem *)feedItem
{
    NSMutableArray *tempArray = [[NSMutableArray arrayWithArray:self.feedItems] mutableCopy];
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

#pragma mark - MWFeedParserDelegate

- (void)feedParserDidStart:(MWFeedParser *)parser
{
    DebugLog(@"Feed parsing stated...");
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
    DebugLog(@"Parsed feed item: %@", item);
    
    __block BOOL itemExists = NO;
    
    [self.feedItems enumerateObjectsWithOptions:NSEnumerationConcurrent
                                     usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                         MWFeedItem *existingItem = (MWFeedItem *)obj;
                                         if ([existingItem.title isEqualToString:item.title] || [existingItem.identifier isEqualToString:item.identifier]) {
                                             itemExists = YES;
                                         }
                                     }];
    
    if (!itemExists) {
        [self addFeedItem:item];
    }
}

- (void)feedParserDidFinish:(MWFeedParser *)parser
{
    DebugLog(@"Feed parsing ended...");
    
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
}

@end
