//
//  SRMainViewController.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/25/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MWFeedItem;
@protocol SRMainContentViewControllerDelegate;

@interface SRMainContentViewController : UIViewController

- (instancetype)initWithFeedItem:(MWFeedItem *)feedItem;

@property (nonatomic, weak) id<SRMainContentViewControllerDelegate> delegate;

@end

@protocol SRMainContentViewControllerDelegate <NSObject>

- (void)refresh:(id)sender;

@end