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
#import "ChatListener.h"

@interface ContactDetailVC : BaseListVC<ChatListener, UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, retain) Contact *contact;
@property (nonatomic, retain) NSArray *yooUsers;
@property (assign) BOOL showButtons;
@property (nonatomic, retain) UIImageView *picture;
@property (nonatomic, retain)     MFMessageComposeViewController *smsController;

- (id)initWithContact:(NSInteger)contactId;



@end
