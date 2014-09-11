//
//  SRMessageViewController.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 1/21/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import "SRMessageViewController.h"
#import "UIImage+Extensions.h"

@interface SRMessageViewController ()
{
    float _width, _height, _x, _y;
}

@end

@implementation SRMessageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (instancetype)initWithMessage:(NSString *)message
{
    self = [super init];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    if (self) {
        _width = [UIScreen mainScreen].bounds.size.width;
        _height = UIDeviceOrientationIsLandscape(self.interfaceOrientation) ? 34.0 : 65.0;
        
        _x = 0.0;
        _y = -_height;
        
        self.view = [[UIView alloc] initWithFrame:CGRectMake(_x, _y, _width, _height)];
        self.view.layer.backgroundColor = [[UIColor colorWithRed:164.0f/255.0f green:194.0f/255.0f blue:244.0f/255.0f alpha:1.0] CGColor];
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 5.0, _width, _height - 5.0)];
        textField.textAlignment = NSTextAlignmentCenter;
        textField.textColor = [UIColor whiteColor];
        textField.text = [message lowercaseString];
        textField.font = [UIFont fontWithName:@"Calibri-Bold" size:18];

        [self.view addSubview:textField];
    }
    
    return self;
}

- (void)orientationChanged:(NSNotification *)notification
{
    [self.view removeFromSuperview];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)animateInView:(UIView *)view
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [view addSubview:self.view];
        [self.view setNeedsDisplay];
        
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.view.alpha = 1.0;
                             self.view.frame = CGRectMake(_x, 0.0, _width, _height);
                         }
                         completion:^(BOOL finished) {
                             
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [UIView animateWithDuration:0.5
                                                       delay:1.5
                                                     options:UIViewAnimationOptionCurveEaseOut
                                                  animations:^{
                                                      self.view.frame = CGRectMake(_x, _y, _width, _height);
                                                      self.view.alpha = 0.0;
                                                  } completion:^(BOOL finished) {
                                                      
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [self.view removeFromSuperview];
                                                      });
                                                  }];
                             });
                         }];
    });
}

@end
