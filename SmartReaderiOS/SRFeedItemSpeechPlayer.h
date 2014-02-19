//
//  SRPlayFeedItems.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 2/15/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SRFeedItemSpeechPlayerDelegate <NSObject>

- (void)playingFeedItemAtIndex:(NSIndexPath *)indexPath;
- (void)finishedPlayingFeedItemAtIndex:(NSIndexPath *)indexPath;
- (void)finishedPlayingAllFeedItems;

@end

@interface SRFeedItemSpeechPlayer : NSObject

@property (nonatomic, copy) NSArray *feedItems;
@property (nonatomic) id<SRFeedItemSpeechPlayerDelegate> delegate;

+ (instancetype)sharedInstance;
- (void)play;
- (void)pause;
- (void)stop;

@end