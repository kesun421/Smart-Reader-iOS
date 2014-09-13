//
//  SRSplashScreenViewController.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 9/4/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import "SRSplashScreenViewController.h"
#import "SRMainTableViewController.h"

@interface SRSplashScreenViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIImageView *textImageView;
@property (weak, nonatomic) IBOutlet UIImageView *starImageView;

@end

@implementation SRSplashScreenViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Place the star image at bottom of the screen.
    self.starImageView.frame = CGRectOffset(self.starImageView.frame, 0.0, [UIScreen mainScreen].bounds.size.height);
    self.starImageView.alpha = 0.0;
    
    // Hide the navigation bar so it doesn't show in the splash screen.
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC);
    dispatch_after(time, dispatch_get_main_queue(), ^(void){
        // Start the rotation animation of the star image.
        CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 4.0];
        rotationAnimation.duration = 1.5;
        [self.starImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
        
        [UIView animateWithDuration:1.5
                         animations:^{
                             self.textImageView.alpha = 0.0;
                             self.starImageView.center = self.view.center;
                             self.starImageView.alpha = 1.0;
                         }
                         completion:^(BOOL finished) {
                             dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
                             dispatch_after(time, dispatch_get_main_queue(), ^(void){
                                 // Unhide the navigation bar so it shows in the main table view.
                                 self.navigationController.navigationBar.hidden = NO;
                                 [self.navigationController pushViewController:[SRMainTableViewController new] animated:NO];
                             });
                         }];
        
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
