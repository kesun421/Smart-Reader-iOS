//
//  SRAddSourceViewController.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/26/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SRAddSourceViewController, SRSource;
@protocol SRAddSourceViewControllerDelegate <NSObject>

- (void)addSourceViewController:(SRAddSourceViewController *)controller didRetrieveSource:(SRSource *)source;

@end

@interface SRAddSourceViewController : UIViewController

@property (nonatomic) id<SRAddSourceViewControllerDelegate> delegate;

@end
