//
//  SRSource.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/26/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWFeedInfo, MWFeedItem;

@interface SRSource : NSObject <NSCoding>

@property (nonatomic) MWFeedInfo *feedInfo;
@property (nonatomic) NSArray *feedItems;
@property (nonatomic, copy) NSString *faviconLink;
@property (nonatomic, copy) NSDate *lastUpdatedDate;
@property (nonatomic, copy) NSString *uuid;

- (void)addFeedItem:(MWFeedItem *)feedItem;

@end