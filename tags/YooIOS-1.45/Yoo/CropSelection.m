//
//  CropSelection.m
//  Yoo
//
//  Created by Arnaud on 04/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "CropSelection.h"

@implementation CropSelection

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor redColor]];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextClearRect(ctx, rect);
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint   (ctx, rect.origin.x, rect.origin.y);
    CGContextAddLineToPoint(ctx, rect.origin.x, rect.origin.y + rect.size.height - 1);
    CGContextAddLineToPoint(ctx, rect.origin.x + rect.size.width - 1, rect.origin.y + rect.size.height - 1);
    CGContextAddLineToPoint(ctx, rect.origin.x + rect.size.width - 1, rect.origin.y);
    CGContextClosePath(ctx);
    
    CGColorRef cgColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.6].CGColor;
    CGContextSetLineWidth(ctx, 4.0f);
    CGContextSetStrokeColorWithColor(ctx, cgColor);
    CGContextSetFillColorWithColor(ctx, cgColor);
    CGContextDrawPath(ctx, kCGPathStroke);
    

    
}


@end
