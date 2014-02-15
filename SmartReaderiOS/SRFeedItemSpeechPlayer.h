//
//  SRPlayFeedItems.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 2/15/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRFeedItemSpeechPlayer : NSObject

@property (nonatomic, copy) NSArray *feedItems;

+ (instancetype)sharedInstance;
- (void)play;
- (void)pause;
- (void)stop;

@end
