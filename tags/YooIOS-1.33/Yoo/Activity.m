//
//  Activity.m
//  Yoo
//
//  Created by Arnaud on 01/04/2015.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import "Activity.h"

@implementation Activity

- (NSArray *)flatten {
    NSMutableArray *ret = [NSMutableArray array];
    for (NSString *section in self.sections) {
        NSArray *recipients = [self.yooRecipients objectForKey:section];
        for (NSArray *tuple in recipients) {
            [ret addObject:tuple];
        }
    }
    return ret;
}

@end
