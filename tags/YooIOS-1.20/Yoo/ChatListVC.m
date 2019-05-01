//
//  ContactListVC.m
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "ChatListVC.h"
#import "ValidationTools.h"
#import "ChatTools.h"
#import "ChatVC.h"
#import "YooUser.h"
#import "ChatDAO.h"
#import "UserDAO.h"
#import "UITools.h"
#import "ContactManager.h"
#import "Contact.h"
#import "ContactListVC.h"
#import "GroupDAO.h"
#import "ContactDAO.h"
#import "YooGroup.h"
#import "YooBroadcast.h"
#import "CustomCell.h"
#import "ImageTools.h"


#import "UICustomAlertViewVC.h"
#import "LocationTools.h"

@interface ChatListVC ()

@end

@implementation ChatListVC

- (id)init {
    self = [super initWithTitle:NSLocalizedString(@"CHAT_LIST", nil)];

//    self.leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    [self.leftBtn setImage:[UIImage imageNamed:@"conference-64.png"] forState:UIControlStateNormal];
//    [self.leftBtn addTarget:self action:@selector(actionPopup:) forControlEvents:UIControlEventTouchUpInside];
    
    self.secRightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.secRightBtn setImage:[UIImage imageNamed:@"conference-64.png"] forState:UIControlStateNormal];
    [self.secRightBtn addTarget:self action:@selector(actionPopup:) forControlEvents:UIControlEventTouchUpInside];

    self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rightBtn setImage:[UIImage imageNamed:@"plus-64.png"] forState:UIControlStateNormal];
    [self.rightBtn addTarget:self action:@selector(startChat) forControlEvents:UIControlEventTouchUpInside];
    
    [[ChatTools sharedInstance] addListener:self];
    [[ContactManager sharedInstance] addListener:self];
    
    [self updateBadge];
    
    return self;
}

- (void)loadView {
    [super loadView];
    self.tableView = [[UITableView alloc] initWithFrame:[self contentRect] style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [self.view addSubview:self.tableView];
}

- (void)dealloc {
    [[ChatTools sharedInstance] removeListener:self];
    [[ContactManager sharedInstance] removeListener:self];
}

- (void)actionPopup:(id)sender {
    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"ACTION", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"BROADCAST", nil), NSLocalizedString(@"NEW_GROUP", nil), nil];
    [actions showFromRect:self.view.frame inView:self.view animated:YES];
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { // Broadcast
        [self broadcast];
    } else if (buttonIndex == 1) { // New Group
        [self createGroup];
    }
}

- (void)update {
    NSMutableArray *tmpSections = [NSMutableArray array];
    NSMutableDictionary *tmpRecipients = [NSMutableDictionary dictionary];
    NSMutableDictionary *tmpContactMap = [NSMutableDictionary dictionary];

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyyMMdd HH:mm:ss"];
    
    // add users
    for (YooUser *yooUser in [UserDAO list]) {
        if (![yooUser isMe] && yooUser.contactId != -1) {
            Contact *contact = [ContactDAO find:yooUser.contactId];
            if (contact == nil) {
                contact = [[ContactManager sharedInstance] find:yooUser.contactId];
            }
            if (contact != nil) {
                NSArray *userMsgs = [[ChatTools sharedInstance] messagesForRecipient:yooUser withPicture:NO];
                if ([userMsgs count] > 0) {
                    YooMessage *last = [userMsgs lastObject];
                    NSString *section = [df stringFromDate:last.date];
                    if (![tmpSections containsObject:section]) {
                        [tmpSections addObject:section];
                        [tmpRecipients setObject:[NSMutableArray array] forKey:section];
                    }
                    NSMutableArray *sectionRecpt = [tmpRecipients objectForKey:section];
                    // order by last received message date
                    int i = 0;
                    for (i = 0; i < sectionRecpt.count; i++) {
                        NSArray *tuple = [sectionRecpt objectAtIndex:i];
                        YooMessage *otherLast = [tuple objectAtIndex:1];
                        if ([last.date compare:otherLast.date] == NSOrderedDescending) {
                            break;
                        }
                    }
                    [sectionRecpt insertObject:@[yooUser, last] atIndex:i];
                    [tmpContactMap setObject:contact forKey:[NSString stringWithFormat:@"%ld", (long)yooUser.contactId]];
                }
                
            }
        }
    }
    
    // add groups
    for (YooGroup *yooGroup in [GroupDAO list]) {
        NSString *section = [df stringFromDate:yooGroup.date != nil ? yooGroup.date : [NSDate date]];
        NSArray *groupMsgs = [[ChatTools sharedInstance] messagesForRecipient:yooGroup withPicture:NO];
        YooMessage *last = nil;
        if ([groupMsgs count] > 0) {
            last = [groupMsgs lastObject];
            section = [df stringFromDate:last.date];
        }
        if (![tmpSections containsObject:section]) {
            [tmpSections addObject:section];
            [tmpRecipients setObject:[NSMutableArray array] forKey:section];
        }
        NSMutableArray *sectionRecpt = [tmpRecipients objectForKey:section];
        // order by last received message date
        int i = 0;
        for (i = 0; i < sectionRecpt.count; i++) {
            NSArray *tuple = [sectionRecpt objectAtIndex:i];
            YooMessage *otherLast = [tuple objectAtIndex:1];
            if ([last.date compare:otherLast.date] == NSOrderedDescending) {
                break;
            }
        }
        if (last == nil) {
            last = [[YooMessage alloc] init];
        }
        [sectionRecpt insertObject:@[yooGroup, last] atIndex:i];
    }

    self.sections = [[[tmpSections sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] reverseObjectEnumerator] allObjects];
    self.contactMap = tmpContactMap;
    self.yooRecipients = tmpRecipients;
    [self.tableView reloadData];
    
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[CustomCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    NSString *section = [self.sections objectAtIndex:indexPath.section];
    NSArray *sectionRcpt = [self.yooRecipients objectForKey:section];
    NSArray *tuple = [sectionRcpt objectAtIndex:indexPath.row];
    NSObject<YooRecipient> *recipient = [tuple objectAtIndex:0];
    Contact *contact = nil;
    NSAttributedString *name = nil;
    BOOL present = YES;
    UIImage *image = nil;
    if ([recipient isKindOfClass:[YooUser class]]) {
        YooUser *yooUser = (YooUser *)recipient;
        contact = [self.contactMap objectForKey:[NSString stringWithFormat:@"%ld", (long)yooUser.contactId]];
        name = [UITools attributedName:contact];
        present = [[ChatTools sharedInstance] isPresent:yooUser];
        if (yooUser != nil && yooUser.picture != nil) {
            image = [UIImage imageWithData:yooUser.picture];
        } else if (contact.image != nil) {
            image = contact.image;
        } else {
            image = [UIImage imageNamed:@"user-icon.png"];
        }
    } else {
        NSDictionary *boldNameAttributes = @{NSFontAttributeName : [UIFont boldSystemFontOfSize:18]};
        name = [[NSAttributedString alloc] initWithString:((YooGroup *)recipient).alias attributes:boldNameAttributes];
        image = [UIImage imageNamed:@"group-icon.png"];
    }
    image = [ImageTools makeRoundedImage:image];
    
    [[cell textLabel] setAttributedText:name];
    [cell.textLabel setFont:[UIFont fontWithName:@"Avenir" size:[UIFont buttonFontSize]]];
    //[cell.textLabel setFrame:CGRectMake(cell.textLabel.frame.origin.x+100, cell.textLabel.frame.origin.y, cell.textLabel.frame.size.width-50, cell.textLabel.frame.size.height)];
    NSInteger cpt = [ChatDAO unreadCountForSender:recipient];
    YooMessage *last = [tuple objectAtIndex:1];
    [cell.detailTextLabel setText:[last toDisplay]];
    [cell.detailTextLabel setFont:[UIFont fontWithName:@"Avenir" size:[UIFont smallSystemFontSize]]];
    [cell.detailTextLabel setTextColor:[UIColor lightGrayColor]];
    cell.dateTime.text = [self getDateTime:section];
    
    // add a green circle when user is online
    for (UIView *tmp in cell.imageView.subviews) {
        [tmp removeFromSuperview];
    }
    if (present && [recipient isKindOfClass:[YooUser class]]) {
        UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(31, 31, 12, 12)];
        [circle setBackgroundColor:[UITools greenColor]];
        circle.layer.cornerRadius = 6;
        [cell.imageView addSubview:circle];
    }
    
    [cell.imageView setImage:image];

    if (cpt > 0) {
        UIFont *font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
        NSString *text = [NSString stringWithFormat:@"%ld", (long)cpt];
        CGSize size = [UITools getStringSize:text font:font constraint:CGSizeMake(100, 22)];
        UILabel *msgLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, size.width + 16, 22)];
        [msgLbl setTextAlignment:NSTextAlignmentCenter];
        [msgLbl setTextColor:[UIColor whiteColor]];
        [msgLbl setFont:font];
        [msgLbl setText:text];
        [msgLbl setBackgroundColor:[UIColor lightGrayColor]];
        msgLbl.layer.cornerRadius = 8;
        msgLbl.layer.masksToBounds = YES;
        [cell setAccessoryView:msgLbl];

    } else {
        [cell setAccessoryView:nil];
    }
    return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *sectionName = [self.sections objectAtIndex:section];
    NSArray *sectionUsers = [self.yooRecipients objectForKey:sectionName];
    return sectionUsers.count;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    NSString *code = [self.sections objectAtIndex:section];
//    NSDateFormatter *df1 = [[NSDateFormatter alloc] init];
//    [df1 setDateFormat:@"yyyyMMdd"];
//    NSDate *date = [df1 dateFromString:code];
//    NSDateFormatter *df2 = [[NSDateFormatter alloc] init];
//    [df2 setDateStyle:NSDateFormatterLongStyle];
//    return [df2 stringFromDate:date];
//}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *section = [self.sections objectAtIndex:indexPath.section];
    NSArray *sectionRecpt = [self.yooRecipients objectForKey:section];
    NSArray *tuple = [sectionRecpt objectAtIndex:indexPath.row];
    NSObject<YooRecipient> *recipient = [tuple objectAtIndex:0];
    ChatMode mode;
    if ([recipient isKindOfClass:[YooUser class]]) {
        mode = cmChat;
    } else {
        mode = cmGroup;
    }
    ChatVC *chatVC = [[ChatVC alloc] initWithMode:mode recipient:recipient];
    [self.navigationController pushViewController:chatVC animated:YES];
}

- (void)lastOnlineChanged:(YooUser *)friend {
    
}

- (void)friendListChanged:(NSArray *)newFriends {
    if (self.isViewLoaded && self.view.window) {
        [self update];
    }
}

- (void)updateBadge {
    // message count
    //NSInteger unread = [ChatDAO unreadCount];
    //[[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:unread > 0 ? [NSString stringWithFormat:@"%ld", (long)unread] : nil];
}

- (void)didReceiveMessage:(YooMessage *)message {
    if (self.isViewLoaded && self.view.window) {
        [self update];
    }
    [self updateBadge];
}

- (void)didLogin:(NSString *)error {
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self update];
    // message count
    //NSInteger unread = [ChatDAO unreadCount];
    //[[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:unread > 0 ? [NSString stringWithFormat:@"%ld", (long)unread] : nil];
}
     
 - (void)addContact {
     UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Add user" message:@"Please enter the user's JID:" delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:@"OK", nil];
     alert.alertViewStyle = UIAlertViewStylePlainTextInput;
     [alert setTag:0];
     [alert show];
 }

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        // add chat
        if (buttonIndex == 1) {
            NSString *jid = [[alertView textFieldAtIndex:0] text];
            NSArray *parts = [jid componentsSeparatedByString:@"@"];
            if (parts.count == 2) {
                [[ChatTools sharedInstance] checkFriend:[parts objectAtIndex:0] domain:[parts objectAtIndex:1]];
            }
        }
    } else if (alertView.tag == 2) {
        // New Group
        if (buttonIndex == 1) {
            // Create the group...
            NSString *groupName = [[alertView textFieldAtIndex:0] text];
            NSString *error = [ValidationTools validateGroupName:groupName];
            if (error == nil) {
                NSMutableArray *jids = [NSMutableArray array];
                for (NSString *name in self.groupUsers) {
                    YooUser *yooUser = [UserDAO find:name domain:YOO_DOMAIN];
                    if (yooUser != nil) {
                        [jids addObject:[yooUser toJID]];
                    }
                }
                [[ChatTools sharedInstance] createGroup:groupName users:jids];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WRONG_GROUPNAME", nil) message:error delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert setTag:4];
                [alert show];

            }
        }
    } else if (alertView.tag == 4) {
        [self showAlertGroup];
    }
}

- (void)didReceiveRegistrationInfo:(NSDictionary *)info {
    // do nothing
}

- (void)didReceiveUserFromPhone:(NSDictionary *)info {
    // do nothing
}

- (void)handlePhoneCall:(CallInfo *)info {
}

- (void)addressBookChanged {
    [self update];
}



- (void)startChat {
    ContactListVC *contactVC = [[ContactListVC alloc] initWithType:clContactSelect listener:self title:NSLocalizedString(@"NEW_CHAT", nil) selected:nil];
    contactVC.tag = 0;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVC];
    [nav setNavigationBarHidden:YES];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)didSelect:(NSArray *)values tag:(NSInteger)tag {
    
    if (tag == 0) { // start chat
        NSString *name = [values objectAtIndex:0];
        YooUser *yooUser = [UserDAO find:name domain:YOO_DOMAIN];
        ChatVC *chatVC = [[ChatVC alloc] initWithMode:cmChat recipient:yooUser];

        [self.navigationController pushViewController:chatVC animated:YES];
    } else if (tag == 1) { // Broadcast
        YooBroadcast *broadcast = [[YooBroadcast alloc] initWithNames:values];
        ChatVC *chatVC = [[ChatVC alloc] initWithMode:cmBroadcast recipient:broadcast];
        [self.navigationController pushViewController:chatVC animated:YES];
    } else if (tag == 2) { // New Group
        
        self.groupUsers = values;
        
        [self showAlertGroup];
    }

}

- (void)showAlertGroup {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NEW_GROUP", nil) message:NSLocalizedString(@"ENTER_GROUP_NAME", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:NSLocalizedString(@"CREATE", nil), nil];
    [alert setTag:2];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[alert textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
    [[alert textFieldAtIndex:0] setReturnKeyType:UIReturnKeyDone];
    [alert show];

}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *section = [self.sections objectAtIndex:indexPath.section];
        NSArray *sectionRcpt = [self.yooRecipients objectForKey:section];
        NSArray *tuple = [sectionRcpt objectAtIndex:indexPath.row];
        NSObject<YooRecipient> *recipient = [tuple objectAtIndex:0];
        [ChatDAO deleteForRecipient:recipient.toJID];
        if ([recipient isKindOfClass:[YooGroup class]]) {
            YooGroup *group = (YooGroup *)recipient;
            NSString *login = [ChatTools sharedInstance].login;
            
            if ([group.name hasPrefix:[NSString stringWithFormat:@"%@-", login]]) {
                // if we are the owner, destroy the group
                [[ChatTools sharedInstance] destroyGroup:group.toJID];
            } else {
                // else, remove ourselves from the group
                [[ChatTools sharedInstance] removeUser:[NSString stringWithFormat:@"%@@%@", login, YOO_DOMAIN] fromGroup:group.toJID];
            }
            [GroupDAO remove:group.toJID];
        }
        [self update];
    }
}

- (void)broadcast {
    ContactListVC *contactVC = [[ContactListVC alloc] initWithType:clContactMultiSelect listener:self title:NSLocalizedString(@"BROADCAST", nil) selected:nil];
    contactVC.tag = 1;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVC];
    [nav setNavigationBarHidden:YES];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
    
}



- (void)createGroup {
    ContactListVC *contactVC = [[ContactListVC alloc] initWithType:clContactMultiSelect listener:self title:NSLocalizedString(@"NEW_GROUP", nil) selected:nil];
    contactVC.tag = 2;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVC];
    [nav setNavigationBarHidden:YES];    
    [self.navigationController presentViewController:nav animated:YES completion:nil];
    
}


- (void)contactsLoaded {
    [self updateBadge];
}

- (NSString*)getDateTime: (NSString*) dateTime
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"YYYYMMdd HH:mm:ss"];
    NSString *date = [df stringFromDate:[NSDate date]];
    
    NSString * dateTimeStr ;
    if([[date substringWithRange:NSMakeRange(0, 10)] isEqual:[dateTime substringWithRange:NSMakeRange(0, 10)]])
    {
        dateTimeStr = [NSString stringWithFormat:@"%@",[dateTime substringWithRange:NSMakeRange(9, 5)]];
    }
    else//past
    {
        //check if it current year
        if ([[date substringWithRange:NSMakeRange(0, 4)] isEqual:[dateTime substringWithRange:NSMakeRange(0, 4)]])
        {
            dateTimeStr = [NSString stringWithFormat:@"%@/%@",[dateTime substringWithRange:NSMakeRange(6, 2)],[dateTime substringWithRange:NSMakeRange(4, 2)]];
        }
        else
        {
            dateTimeStr = [NSString stringWithFormat:@"%@/%@/%@",[dateTime substringWithRange:NSMakeRange(6, 2)],[dateTime substringWithRange:NSMakeRange(4, 2)],[dateTime substringWithRange:NSMakeRange(0, 4)]];
        }
    }

    return dateTimeStr;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    //[searchBar resignFirstResponder];
    [searchBar performSelector:@selector(resignFirstResponder)
                    withObject:nil
                    afterDelay:0];
}
@end
