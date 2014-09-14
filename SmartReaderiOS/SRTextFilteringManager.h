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
- (void)processFeedItemAsLiked:(MWFeedItem *)feedItem;
- (void)findInterestingFeedItemsFromSources:(NSArray *)sources;

@property (nonatomic, weak) id<SRTextFilteringManagerDelegate> delegate;
@property (nonatomic) NSArray *interestingFeedItems;
@property (nonatomic) int interestingArticlesCap;

@end

@protocol SRTextFilteringManagerDelegate <NSObject>

- (void)didFinishFindinglikableFeedItems;

@end