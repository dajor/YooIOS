//
//  CropHandle.m
//  Yoo
//
//  Created by Arnaud on 04/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "CropHandle.h"

@implementation CropHandle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    return self;
}


- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect rect2 = CGRectInset(rect, 10, 10);
    CGContextBeginPath(ctx);
    
    CGColorRef cgColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.6].CGColor;
    CGContextSetFillColorWithColor(ctx, cgColor);
    CGContextDrawPath(ctx, kCGPathStroke);
    
    CGContextFillEllipseInRect(ctx, rect2);
}


@end
