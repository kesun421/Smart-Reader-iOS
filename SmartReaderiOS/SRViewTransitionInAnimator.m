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
        toViewController.view.transform = CGAffineTransformMakeTranslation(toViewController.view.frame.size.width, 0.0);
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            toViewController.view.transform = CGAffineTransformIdentity;
            fromViewController.view.transform = CGAffineTransformMakeTranslation(-fromViewController.view.frame.size.width, 0.0);
        } completion:^(BOOL finished) {
            fromViewController.view.transform = CGAffineTransformIdentity;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}

@end
