//
//  SRMainViewController.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/25/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MWFeedItem;

@interface SRMainContentViewController : UIViewController

- (instancetype)initWithFeedItem:(MWFeedItem *)feedItem;

@end
