//
//  SRViewTransitionOutAnimator.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 9/14/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import "SRViewTransitionOutAnimator.h"

@implementation SRViewTransitionOutAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [[transitionContext containerView] addSubview:toViewController.view];
    
    toViewController.view.transform = CGAffineTransformMakeTranslation(-toViewController.view.frame.size.width, 0.0);
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        toViewController.view.transform = CGAffineTransformIdentity;
        fromViewController.view.transform = CGAffineTransformMakeTranslation(fromViewController.view.frame.size.width, 0.0);
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end
