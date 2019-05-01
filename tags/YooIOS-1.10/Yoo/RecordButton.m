//
//  RecordButton.m
//  Yoo
//
//  Created by Arnaud on 09/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "RecordButton.h"

@implementation RecordButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextBeginPath(ctx);
    
    CGColorRef lightRedColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.5].CGColor;
    CGContextSetFillColorWithColor(ctx, lightRedColor);
    //CGContextDrawPath(ctx, kCGPathStroke);
    
    CGContextFillEllipseInRect(ctx, rect);

    CGColorRef redColor = [UIColor redColor].CGColor;
    CGContextSetFillColorWithColor(ctx, redColor);
    CGRect rect2 = CGRectInset(rect, 8, 8);
    CGContextFillEllipseInRect(ctx, rect2);
}

@end
