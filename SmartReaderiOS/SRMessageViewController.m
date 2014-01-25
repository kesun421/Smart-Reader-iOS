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
        _width = message.length > 15 ? 260.0 : 160.0;
        _height = 40.0;
        
        if (UIDeviceOrientationIsLandscape(self.interfaceOrientation)) {
            _x = [UIScreen mainScreen].bounds.size.height;
            _y = 50.0;
        }
        else {
            _x = [UIScreen mainScreen].bounds.size.width;
            _y = 60.0;
        }
        
        self.view = [[UIView alloc] initWithFrame:CGRectMake(_x, _y, _width, _height)];
        self.view.layer.borderColor = [[UIColor grayColor] CGColor];
        self.view.layer.borderWidth = 0.5;
        self.view.layer.shadowColor = [[UIColor grayColor] CGColor];
        self.view.layer.shadowOffset = CGSizeMake(-1.5, 1.5);
        self.view.layer.shadowRadius = 5;
        self.view.layer.shadowOpacity = 0.5;
        self.view.layer.backgroundColor = [[UIColor colorWithRed:249.0f/255.0f green:253.0f/255.0f blue:255.0f/255.0f alpha:1.0] CGColor];
        self.view.alpha = 0.5;
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 20.0, 20.0)];
        imageView.center = CGPointMake(15.0, _height/2.0);
        imageView.image = [[UIImage imageNamed:@"info.png"] resizeImageToSize:CGSizeMake(20.0, 20.0)];
        [self.view addSubview:imageView];
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(30.0, 0.0, _width - 30.0 - 10.0, _height)];
        textField.textAlignment = NSTextAlignmentLeft;
        textField.text = message;
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

- (void)animate
{
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.view.alpha = 1.0;
                         self.view.frame = CGRectMake(_x - _width + 5.0, _y, _width, _height);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.5
                                               delay:1.5
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              self.view.frame = CGRectMake(_x, _y, _width, _height);
                                              self.view.alpha = 0.0;
                                          } completion:^(BOOL finished) {
                                              [self.view removeFromSuperview];
                                          }];
                     }];
}

@end
