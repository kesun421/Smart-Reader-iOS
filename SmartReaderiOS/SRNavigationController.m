//
//  SRNavigationController.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 9/13/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import "SRNavigationController.h"

@interface SRNavigationController ()

@end

@implementation SRNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

@end
