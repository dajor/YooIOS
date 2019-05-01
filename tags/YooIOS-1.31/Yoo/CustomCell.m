//
//  CustomCell.m
//  Yoo
//
//  Created by Arnaud on 10/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "CustomCell.h"

@implementation CustomCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    self.dateTime = [[UILabel alloc]init];
    self.dateTime.backgroundColor = [UIColor clearColor];
    self.dateTime.textAlignment = NSTextAlignmentRight;
    [self.dateTime setFont:[UIFont fontWithName:@"Avenir" size:11]];
    self.dateTime.textColor = [UIColor lightGrayColor];
    [self addSubview:self.dateTime];
    
    return self;
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectInset(self.imageView.frame, 2, 2);
    
    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y, self.frame.size.width*0.6, self.textLabel.frame.size.height);
    self.detailTextLabel.frame = CGRectMake(self.detailTextLabel.frame.origin.x, self.detailTextLabel.frame.origin.y, self.frame.size.width*0.6, self.detailTextLabel.frame.size.height);
    
    self.dateTime.frame = CGRectMake(self.frame.size.width-120, self.frame.size.height-20, 100, 20);
    self.accessoryView.frame = CGRectMake(self.accessoryView.frame.origin.x-5, self.accessoryView.frame.origin.y-7, self.accessoryView.frame.size.width, self.accessoryView.frame.size.height);
}


@end
