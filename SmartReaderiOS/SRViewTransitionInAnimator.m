//
//  SRCustomAnimator.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 9/14/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import "SRViewTransitionInAnimator.h"
#import "SRSplashScreenViewController.h"
#import "SRMainTableViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation SRViewTransitionInAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    if ([fromViewController isKindOfClass:[SRSplashScreenViewController class]] && [toViewController isKindOfClass:[SRMainTableViewController class]]) {
        return 1.0;
    }
    else {
        return 0.5;
    }
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    [[transitionContext containerView] addSubview:toViewController.view];
    
    if ([fromViewController isKindOfClass:[SRSplashScreenViewController class]] && [toViewController isKindOfClass:[SRMainTableViewController class]]) {
        toViewController.view.alpha = 0.0;
        toViewController.navigationController.navigationBar.alpha = 0.0;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            toViewController.view.alpha = 1.0;
            toViewController.navigationController.navigationBar.alpha = 1.0;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
    else {
        // Rotate off screen.
        CATransform3D tp = CATransform3DIdentity;
        tp.m34 = 1.0/ -500;
        tp = CATransform3DTranslate(tp, toViewController.view.frame.size.width, 0.0, 300.0f);
        tp = CATransform3DRotate(tp, M_PI * 30 /180, 0.0f, 1.0f, 0.8f);
        toViewController.view.layer.transform = tp;
        
        // Add shadow.
        toViewController.view.layer.masksToBounds = NO;
        toViewController.view.layer.shadowOffset = CGSizeMake(-10, 10);
        toViewController.view.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
        toViewController.view.layer.shadowRadius = 5;
        toViewController.view.layer.shadowOpacity = 0.5;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            toViewController.view.layer.transform = CATransform3DIdentity;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}

@end
