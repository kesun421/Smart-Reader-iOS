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

@property (weak, nonatomic) UIView *parentView;
@property (weak, nonatomic) UIViewController *msgParentViewController;
@property (nonatomic) UITextField *textField;

@end

@implementation SRMessageViewController

- (instancetype)initWithParentViewControllr:(UIViewController *)viewController message:(NSString *)message
{
    self = [super init];
    
    if (self) {
        self.msgParentViewController = viewController;
        self.parentView = self.msgParentViewController.view;
        
        _width = self.parentView.frame.size.width;
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            _height = ((UINavigationController *)self.msgParentViewController).navigationBar.frame.size.height;
            _height = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? _height : _height + ((UINavigationController *)self.msgParentViewController).navigationBar.frame.origin.y;
        }
        else {
            _height = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? 34.0 : 65.0;
        }
        
        _x = 0.0;
        _y = -_height;
        
        self.view = [[UIView alloc] initWithFrame:CGRectMake(_x, _y, _width, _height)];
        self.view.backgroundColor = [UIColor colorWithRed:164.0f/255.0f green:194.0f/255.0f blue:244.0f/255.0f alpha:1.0];
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 5.0, _width, _height - 5.0)];
        self.textField.textAlignment = NSTextAlignmentCenter;
        self.textField.textColor = [UIColor whiteColor];
        self.textField.font = [UIFont fontWithName:@"Calibri-Bold" size:18];
        self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        self.textField.text = message;
        
        [self.view addSubview:self.textField];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationChanged:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    
    return self;
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

- (void)show
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.parentView addSubview:self.view];
        [self.view setNeedsDisplay];
        
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.view.alpha = 1.0;
                             self.view.transform = CGAffineTransformMakeTranslation(0.0, _height);
                         }
                         completion:^(BOOL finished) {
                             
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [UIView animateWithDuration:0.5
                                                       delay:1.5
                                                     options:UIViewAnimationOptionCurveEaseOut
                                                  animations:^{
                                                      self.view.alpha = 0.0;
                                                      self.view.transform = CGAffineTransformMakeTranslation(0.0, -_height);
                                                  } completion:^(BOOL finished) {
                                                      
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [self.view removeFromSuperview];
                                                      });
                                                  }];
                             });
                         }];
    });
}

- (void)orientationChanged:(NSNotification *)notification
{
    // Adjust the size of the message view by the orientation of the device.
    _width = self.parentView.frame.size.width;
    if ([self.msgParentViewController isKindOfClass:[UINavigationController class]]) {
        _height = ((UINavigationController *)self.msgParentViewController).navigationBar.frame.size.height;
        _height = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? _height : _height + ((UINavigationController *)self.msgParentViewController).navigationBar.frame.origin.y;
    }
    else {
        _height = UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? 34.0 : 65.0;
    }
    
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, _width, _height);
    self.textField.frame = CGRectMake(0.0, 5.0, _width, _height - 5.0);
}

@end
