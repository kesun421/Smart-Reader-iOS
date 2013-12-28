//
//  SRSourceManager.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 12/27/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SRSource;
@protocol SRSourceManagerDelegate;

@interface SRSourceManager : NSObject

@property (nonatomic) NSArray *sources;
@property (nonatomic, weak) id<SRSourceManagerDelegate> backgroundDelegate;
@property (nonatomic, weak) id<SRSourceManagerDelegate> mainDelegate;
@property (nonatomic, weak) id<SRSourceManagerDelegate> secondaryDelegate;

+ (instancetype)sharedManager;

- (void)loadSources;
- (void)deleteSources;
- (void)saveSources;
- (void)refreshSources;
- (void)addSource:(SRSource *)source;

@end

@protocol SRSourceManagerDelegate <NSObject>

- (void)didFinishRefreshingAllSourcesWithError:(NSError *)error;

@end
