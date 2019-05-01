//
//  MenuVC.h
//  Yoo
//
//  Created by Vanroth on 2/17/15.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatListener.h"
#import "Activity.h"

@interface MenuVC : UIViewController<UITableViewDelegate, UITableViewDataSource, ChatListener>{
    NSIndexPath *selectedIndex;
    UIView *headerView;
}

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSArray *options;
@property (nonatomic, retain) NSArray *icons;
@property (nonatomic, retain) UILabel *unReadlbl;
@property (nonatomic, retain) Activity *activity;
@property (nonatomic, retain) NSArray *recipients;

@end
