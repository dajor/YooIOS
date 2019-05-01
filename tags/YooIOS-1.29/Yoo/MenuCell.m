//
//  MenuCell.m
//  Yoo
//
//  Created by Arnaud on 01/04/2015.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import "MenuCell.h"

@implementation MenuCell

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectInset(self.imageView.frame, 8, 8);

}

@end
