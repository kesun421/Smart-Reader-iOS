//
//  SRNavigationController.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 9/13/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import "SRNavigationController.h"
#import "SRViewTransitionInAnimator.h"
#import "SRViewTransitionOutAnimator.h"

@interface SRNavigationController () <UINavigationControllerDelegate>

@property (nonatomic) id<UIViewControllerAnimatedTransitioning> transitionInAnimator;
@property (nonatomic) id<UIViewControllerAnimatedTransitioning> transitionOutAnimator;

@end

@implementation SRNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    UIColor *darkColor = [UIColor colorWithRed:66.0f/255.0f green:66.0f/255.0f blue:66.0f/255.0f alpha:1.0];
    self.navigationBar.tintColor = darkColor;
    self.navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName : darkColor, NSFontAttributeName : [UIFont fontWithName:@"Lucida Sans" size:18] };
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.delegate = self;
    self.transitionInAnimator = [SRViewTransitionInAnimator new];
    self.transitionOutAnimator = [SRViewTransitionOutAnimator new];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    if (operation == UINavigationControllerOperationPush) {
        return self.transitionInAnimator;
    }
    else if (operation == UINavigationControllerOperationPop) {
        return self.transitionOutAnimator;
    }
    
    return nil;
}

@end
