//
//  SRRefreshViewController.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 9/22/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import "SRRefreshViewController.h"

@interface SRRefreshViewController ()

@end

@implementation SRRefreshViewController

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super init];
    
    if (self) {
        self.view.frame = frame;

        // Set background color to white to cover the original view.
        self.view.backgroundColor = [UIColor whiteColor];
        
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        // Setup the view hierarchy, where one subview holds three smaller views which acts as indicators.
        float dotWidth = 8.0;
        float dotMargin = 10.0;
        
        UIView *mainSubView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, dotWidth * 3 + dotMargin * 2, dotWidth)];
        mainSubView.center = self.view.center;
        mainSubView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.view addSubview:mainSubView];
        
        UIColor *dotViewBackgroundColor = [UIColor colorWithRed:164.0f/255.0f green:194.0f/255.0f blue:244.0f/255.0f alpha:1.0];
        
        for (int i = 0; i < 3; i++) {
            UIView *dotView = [[UIView alloc] initWithFrame:CGRectMake((dotWidth + dotMargin) * i, 0.0, dotWidth, dotWidth)];
            dotView.layer.cornerRadius = dotWidth / 2;
            dotView.backgroundColor = dotViewBackgroundColor;
            
            [mainSubView addSubview:dotView];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateKeyframesWithDuration:0.75
                                               delay:0.30 * i
                                             options:UIViewKeyframeAnimationOptionRepeat | UIViewKeyframeAnimationOptionAutoreverse
                                          animations:^{
                                              dotView.alpha = 0.0;
                                          }
                                          completion:nil];
            });
        }
    }
    
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
