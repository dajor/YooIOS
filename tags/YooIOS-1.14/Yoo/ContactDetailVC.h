//
//  ContactDetailVC.h
//  Yoo
//
//  Created by Arnaud on 06/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YooUser.h"
#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "BaseListVC.h"
#import "Contact.h"

@interface ContactDetailVC : BaseListVC<UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, retain) Contact *contact;
@property (nonatomic, retain) NSArray *yooUsers;
@property (assign) BOOL showChatButton;
@property (assign) BOOL showCallButton;

- (id)initWithContact:(NSInteger)contactId;



@end
