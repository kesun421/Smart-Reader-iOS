//
//  UIImage+Extensions.m
//  SmartReaderiOS
//
//  Created by Ke Sun on 1/20/14.
//  Copyright (c) 2014 Ke Sun. All rights reserved.
//

#import "UIImage+Extensions.h"

@implementation UIImage (Extensions)

- (UIImage *)resizeImageToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
