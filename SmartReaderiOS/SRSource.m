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

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.feedInfo = [decoder decodeObjectForKey:@"feedInfo"];
        self.feedItems = [decoder decodeObjectForKey:@"feedItems"];
        self.faviconLink = [decoder decodeObjectForKey:@"faviconLink"];
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
    [encoder encodeObject:self.lastUpdatedDate forKey:@"lastUpdatedDate"];
    [encoder encodeObject:self.uuid forKey:@"uuid"];
}

@end
