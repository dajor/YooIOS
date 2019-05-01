//
//  CustomCell.m
//  Yoo
//
//  Created by Arnaud on 10/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "CustomCell.h"

@implementation CustomCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = CGRectInset(self.imageView.frame, 2, 2);
//    CALayer *cellImageLayer = self.imageView.layer;
//    [cellImageLayer setCornerRadius:self.imageView.frame.size.height/2];
//    [cellImageLayer setMasksToBounds:YES];
}


@end
