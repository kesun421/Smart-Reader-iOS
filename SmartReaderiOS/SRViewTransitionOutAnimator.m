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
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        CATransform3D tp = CATransform3DIdentity;
        tp.m34 = 1.0/ -500;
        tp = CATransform3DTranslate(tp, 300.0f, -30.0f, 300.0f);
        tp = CATransform3DRotate(tp, M_PI * 20 /180, 0.0f,1.0f, 0.8f);
        fromViewController.view.layer.transform = tp;
        fromViewController.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end
