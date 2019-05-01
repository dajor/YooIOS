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

@interface ChatListVC : UITableViewController<UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate, ChatListener, PicklistListener>

@property (nonatomic, retain) NSArray *sections;
@property (nonatomic, retain) NSDictionary *yooRecipients;
@property (nonatomic, retain) NSDictionary *contactMap;
@property (nonatomic, retain) NSDictionary *msgCount;
@property (nonatomic, retain) NSArray *groupUsers;

@end

