//
//  FirstViewController.h
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatListener.h"
#import "PicklistListener.h"
#import "ContactListener.h"
#import "BaseListVC.h"
#import "Activity.h"

@interface ChatListVC : BaseListVC<UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate, ChatListener, ContactListener, PicklistListener>


@property (nonatomic, retain) Activity *activity;
@property (nonatomic, retain) NSDictionary *msgCount;
@property (nonatomic, retain) NSArray *groupUsers;

@end

