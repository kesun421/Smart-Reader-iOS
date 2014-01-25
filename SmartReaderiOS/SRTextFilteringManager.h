//
//  SRTextFilteringManager.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 12/31/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWFeedItem;
@protocol SRTextFilteringManagerDelegate;

@interface SRTextFilteringManager : NSObject

+ (instancetype)sharedManager;
- (void)processFeedItem:(MWFeedItem *)feedItem AsLiked:(BOOL)liked;
- (void)findlikableFeedItemsFromSources:(NSArray *)sources;

@property (nonatomic, weak) id<SRTextFilteringManagerDelegate> delegate;
@property (nonatomic) NSArray *likableFeedItems;

@end

@protocol SRTextFilteringManagerDelegate <NSObject>

- (void)didFinishFindinglikableFeedItems;

@end