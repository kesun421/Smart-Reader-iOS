//
//  SRMessageViewController.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 1/21/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import "SRMessageViewController.h"

@interface SRMessageViewController ()
{
    float _width, _height, _centerX, _centerY;
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

- (instancetype)initWithSize:(CGSize)size message:(NSString *)message
{
    self = [super init];
    
    if (self) {
        _width = size.width;
        _height = size.height;
        _centerX = [UIScreen mainScreen].bounds.size.width / 2.0;
        _centerY = [UIScreen mainScreen].bounds.size.height / 2.0;
        
        self.view = [[UIView alloc] initWithFrame:CGRectMake(_centerX - _width / 2.0, [UIScreen mainScreen].bounds.size.height, _width, _height)];
        self.view.layer.borderColor = [[UIColor grayColor] CGColor];
        self.view.layer.borderWidth = 0.25;
        self.view.layer.cornerRadius = 10.0;
        self.view.layer.shadowColor = [[UIColor grayColor] CGColor];
        self.view.layer.shadowOffset = CGSizeMake(-2.5, 2.5);
        self.view.layer.shadowRadius = 5;
        self.view.layer.shadowOpacity = 0.5;
        self.view.layer.backgroundColor = [[UIColor colorWithRed:249.0f/255.0f green:253.0f/255.0f blue:255.0f/255.0f alpha:1.0] CGColor];

        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10.0, 0.0, _width - 10.0 * 2, _height)];
        textField.textAlignment = NSTextAlignmentCenter;
        textField.text = message;
        [self.view addSubview:textField];
    }
    
    return self;
}

- (void)animate
{
    [UIView animateWithDuration:0.75
                          delay:0.25
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.view.center = CGPointMake(_centerX, _centerY);
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:1.0
                                               delay:0.5
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              self.view.alpha = 0.0;
                                          } completion:^(BOOL finished) {
                                              [self.view removeFromSuperview];
                                          }];
                     }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
