//
//  BaseListVC.m
//  Yoo
//
//  Created by Arnaud on 07/01/2015.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import "BaseListVC.h"

@interface BaseListVC ()

@end

@implementation BaseListVC

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    // disabled with iOS 8.0, there is a bug that causes a crash
    // works with 7.x and 8.1
    NSOperatingSystemVersion iOS_8_1 = (NSOperatingSystemVersion){8, 1, 0};
    if (![[NSProcessInfo processInfo] respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)]
        || [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:iOS_8_1]) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
        header.textLabel.font = [UIFont fontWithName:@"Avenir-Heavy" size:[UIFont systemFontSize]];
    }
}




- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}

@end
