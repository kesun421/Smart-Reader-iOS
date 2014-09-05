//
//  SRSplashScreenViewController.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 9/4/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import "SRSplashScreenViewController.h"

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
    
    if ([UIScreen mainScreen].bounds.size.height == 568.00) {
        self.backgroundImageView.image = [UIImage imageNamed:@"LaunchImage_Background_640x1136.png"];
    }
    else {
        self.backgroundImageView.image = [UIImage imageNamed:@"LaunchImage_Background_640x960.png"];
    }
    
    // Place the star image at bottom of the screen.
    self.starImageView.frame = CGRectOffset(self.starImageView.frame, 0.0, [UIScreen mainScreen].bounds.size.height);
    self.starImageView.alpha = 0.0;

    // Start the rotation animation of the star image.
    CABasicAnimation* rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 4.0];
    rotationAnimation.duration = 2.0;
    [self.starImageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:1.5
                     animations:^{
                         self.textImageView.alpha = 0.0;
                         self.starImageView.center = self.view.center;
                         self.starImageView.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC);
                         dispatch_after(time, dispatch_get_main_queue(), ^(void){
                             [self dismissViewControllerAnimated:NO completion:nil];
                         });
                     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
