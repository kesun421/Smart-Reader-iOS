//
//  SRMessageViewController.h
//  SmartReaderiOS
//
//  Created by Ke Sun on 1/21/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SRMessageViewController : UIViewController

- (instancetype)initWithParentViewControllr:(UIViewController *)viewController message:(NSString *)message;
- (void)show;

@end
