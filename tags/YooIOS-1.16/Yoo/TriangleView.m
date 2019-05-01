//
//  TriangleView.m
//  Yoo
//
//  Created by Arnaud on 14/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "TriangleView.h"

@implementation TriangleView

- (id)initWithFrame:(CGRect)frame left:(BOOL)pLeft color:(UIColor *)pColor
{
    self = [super initWithFrame:frame];
    self.left = pLeft;
    self.color = pColor;
    return self;
}


- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint   (ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));  // top left
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMinY(rect));  // top right
    if (self.left) {
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));  // bottom left
    } else {
        CGContextAddLineToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect));  // bottom right
        
    }
    CGContextClosePath(ctx);
    
    CGColorRef cgColor = self.color.CGColor;
    CGContextSetFillColorWithColor(ctx, cgColor);
    CGContextFillPath(ctx);
}

@end
