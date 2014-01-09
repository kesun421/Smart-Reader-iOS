//
//  SRSecondaryTableViewController.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 11/25/13.
//  Copyright (c) 2013 Ke Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SRSource;
@protocol SRSecondaryTableViewControllerDelegate;

@interface SRSecondaryTableViewController : UITableViewController

- (instancetype)initWithSource:(SRSource *)source;

@property (nonatomic, weak) id<SRSecondaryTableViewControllerDelegate> delegate;

@end

@protocol SRSecondaryTableViewControllerDelegate <NSObject>

- (void)refresh:(id)sender;

@end