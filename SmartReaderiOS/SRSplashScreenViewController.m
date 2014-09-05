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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:1.5
                     animations:^{
                         self.textImageView.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         [self dismissViewControllerAnimated:NO completion:nil];
                     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
