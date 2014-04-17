//
//  SRTableViewCell.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 4/16/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import "SRTableViewCell.h"

@implementation SRTableViewCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.detailTextLabel.frame = CGRectOffset(self.detailTextLabel.frame, 0.0, 5.0);
}

@end
