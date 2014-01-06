//
//  SRSource.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/26/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWFeedInfo, MWFeedItem;
@protocol SRSourceDelegate;

@interface SRSource : NSObject <NSCoding>

@property (nonatomic) MWFeedInfo *feedInfo;
@property (nonatomic) NSArray *feedItems;
@property (nonatomic, copy) NSString *faviconLink;
@property (nonatomic, copy) NSString *feedLink;
@property (nonatomic, copy) NSDate *lastUpdatedDate;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, weak) id<SRSourceDelegate> delegate;
@property (assign, readonly) int newCount;
@property (assign, readonly) int interestingCount;

- (void)addFeedItem:(MWFeedItem *)feedItem;
- (void)refresh;
/** Remove entries that are older than two weeks. */
- (void)removeOldFeedItems;
- (void)parseFeedItemTokens;

@end

@protocol SRSourceDelegate <NSObject>

- (void)didFinishRefreshingSource:(SRSource *)source withError:(NSError *)error;

@end