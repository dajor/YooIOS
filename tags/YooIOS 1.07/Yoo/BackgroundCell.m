//
//  BackgroundCell.m
//  Yoo
//
//  Created by Arnaud on 22/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "BackgroundCell.h"

@implementation BackgroundCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self.contentView addSubview:self.imageView];
    }
    return self;
}


@end
