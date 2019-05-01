//
//  ContactListVC.m
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "ChatListVC.h"
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
    self = [super initWithStyle:UITableViewStylePlain];
    self.title = NSLocalizedString(@"CHAT_LIST", nil);;
    [UITools setupTitleBar];
    [[ChatTools sharedInstance] addListener:self];


    [self.navigationItem setLeftBarButtonItem:
     [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionPopup:)]
     ];
    
    [self.navigationItem setRightBarButtonItem:
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(startChat)]
    ];
    
    NSInteger unread = [ChatDAO unreadCount];
    [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:unread > 0 ? [NSString stringWithFormat:@"%ld", (long)unread] : nil];
    return self;
}

- (void)dealloc {
    [[ChatTools sharedInstance] removeListener:self];
}

- (void)actionPopup:(id)sender {
    UIActionSheet *actions = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"ACTION", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"BROADCAST", nil), NSLocalizedString(@"NEW_GROUP", nil), nil];
    [actions showFromBarButtonItem:sender animated:YES];
    
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
    [df setDateFormat:@"yyyyMMdd"];

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
                    [sectionRecpt addObject:yooUser];
                    [tmpContactMap setObject:contact forKey:[NSString stringWithFormat:@"%d", yooUser.contactId]];
                }
                
            }
        }
    }
    
    // add groups
    for (YooGroup *yooGroup in [GroupDAO list]) {
        NSString *section = [df stringFromDate:yooGroup.date != nil ? yooGroup.date : [NSDate date]];
        NSArray *groupMsgs = [[ChatTools sharedInstance] messagesForRecipient:yooGroup withPicture:NO];
        if ([groupMsgs count] > 0) {
            YooMessage *last = [groupMsgs lastObject];
            section = [df stringFromDate:last.date];
        }
        if (![tmpSections containsObject:section]) {
            [tmpSections addObject:section];
            [tmpRecipients setObject:[NSMutableArray array] forKey:section];
        }
        NSMutableArray *sectionRecpt = [tmpRecipients objectForKey:section];
        [sectionRecpt addObject:yooGroup];
    }

    self.sections = [[[tmpSections sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] reverseObjectEnumerator] allObjects];
    self.contactMap = tmpContactMap;
    self.yooRecipients = tmpRecipients;
    [self.tableView reloadData];
    
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[CustomCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    NSString *section = [self.sections objectAtIndex:indexPath.section];
    NSArray *sectionRcpt = [self.yooRecipients objectForKey:section];
    NSObject<YooRecipient> *recipient = [sectionRcpt objectAtIndex:indexPath.row];
    Contact *contact = nil;
    NSAttributedString *name = nil;
    BOOL present = YES;
    UIImage *image = nil;
    if ([recipient isKindOfClass:[YooUser class]]) {
        YooUser *yooUser = (YooUser *)recipient;
        contact = [self.contactMap objectForKey:[NSString stringWithFormat:@"%d", yooUser.contactId]];
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
    [cell.textLabel setTextColor:present ? [UIColor blackColor] : [UIColor lightGrayColor]];
    NSInteger cpt = [ChatDAO unreadCountForSender:recipient];
    NSArray *userMsgs = [[ChatTools sharedInstance] messagesForRecipient:recipient withPicture:NO];
    YooMessage *last = [userMsgs lastObject];
    [cell.detailTextLabel setText:last.message];
    [cell.detailTextLabel setTextColor:[UIColor lightGrayColor]];

    
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *code = [self.sections objectAtIndex:section];
    NSDateFormatter *df1 = [[NSDateFormatter alloc] init];
    [df1 setDateFormat:@"yyyyMMdd"];
    NSDate *date = [df1 dateFromString:code];
    NSDateFormatter *df2 = [[NSDateFormatter alloc] init];
    [df2 setDateStyle:NSDateFormatterLongStyle];
    return [df2 stringFromDate:date];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *section = [self.sections objectAtIndex:indexPath.section];
    NSArray *sectionRecpt = [self.yooRecipients objectForKey:section];
    NSObject<YooRecipient> *recipient = [sectionRecpt objectAtIndex:indexPath.row];
    ChatMode mode;
    if ([recipient isKindOfClass:[YooUser class]]) {
        mode = cmChat;
    } else {
        mode = cmGroup;
    }
    ChatVC *chatVC = [[ChatVC alloc] initWithMode:mode recipient:recipient];
    [self.navigationController pushViewController:chatVC animated:YES];
}

- (void)friendListChanged:(NSArray *)newFriends {
    if (self.isViewLoaded && self.view.window) {
        [self update];
    }
}

- (void)didReceiveMessage:(YooMessage *)message {
    if (self.isViewLoaded && self.view.window) {
        [self update];
    }
    // message count
    NSInteger unread = [ChatDAO unreadCount];
    [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:unread > 0 ? [NSString stringWithFormat:@"%ld", (long)unread] : nil];
    if(message.type == ymtCallRequest){
        NSUserDefaults *defaultUser = [NSUserDefaults standardUserDefaults];
        NSString *login = [defaultUser objectForKey:@"login"];
        YooUser *fromRecipient = (YooUser *) message.from;
        // Check it avoid echo to current user
        if(![login isEqualToString:fromRecipient.name]){
            UICustomAlertViewVC *alert = [[UICustomAlertViewVC alloc] initWithTitle:@"Yoo" message:message.message delegate:self cancelButtonTitle:@"Decline" otherButtonTitles:@"Accept", nil];
            alert.yooMessage = message;
            alert.tag = 3;
            [alert show];
        }
    }
}

- (void)didLogin:(NSString *)error {
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self update];
    // message count
    NSInteger unread = [ChatDAO unreadCount];
    [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:unread > 0 ? [NSString stringWithFormat:@"%ld", (long)unread] : nil];
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
            if (groupName.length > 0) {
                NSMutableArray *jids = [NSMutableArray array];
                for (NSString *name in self.groupUsers) {
                    YooUser *yooUser = [UserDAO find:name domain:YOO_DOMAIN];
                    if (yooUser != nil) {
                        [jids addObject:[yooUser toJID]];
                    }
                }
                [[ChatTools sharedInstance] createGroup:groupName users:jids];
            }
        }
    }else if(alertView.tag == 3){
        UICustomAlertViewVC *alert = (UICustomAlertViewVC *) alertView;
        YooMessage *yooMsg = alert.yooMessage;
        YooMessage *payload = [[YooMessage alloc] init];
        payload.to = yooMsg.from;
        payload.location = [LocationTools sharedInstance].location.coordinate;
//        payload.thread = yooMsg.thread;
        payload.type = ymtCallStatus;
        if (buttonIndex == 0){
            // Decline
            payload.message = @"reject";
        }else{
            // Accept
            payload.message = @"approval";
            NSString *telNumber = yooMsg.conferenceNumber;
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", telNumber]]];
        }
        [[ChatTools sharedInstance] sendMessage:payload];
    }
}

- (void)didReceiveRegistrationInfo:(NSDictionary *)info {
    // do nothing
}

- (void)didReceiveUserFromPhone:(NSDictionary *)info {
    // do nothing
}


- (void)addressBookChanged {
    [self update];
}

- (void)startChat {
    ContactListVC *contactVC = [[ContactListVC alloc] initWithType:clContactSelect listener:self title:NSLocalizedString(@"NEW_CHAT", nil) selected:nil];
    contactVC.tag = 0;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVC];
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
        
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NEW_GROUP", nil) message:NSLocalizedString(@"ENTER_GROUP_NAME", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:NSLocalizedString(@"CREATE", nil), nil];
        [alert setTag:2];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[alert textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
        [[alert textFieldAtIndex:0] setReturnKeyType:UIReturnKeyDone];
        [alert show];
    }
        //
        //- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

        //}

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
        NSObject<YooRecipient> *recipient = [sectionRcpt objectAtIndex:indexPath.row];
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
    [self.navigationController presentViewController:nav animated:YES completion:nil];
    
}

- (void)createGroup {
    ContactListVC *contactVC = [[ContactListVC alloc] initWithType:clContactMultiSelect listener:self title:NSLocalizedString(@"NEW_GROUP", nil) selected:nil];
    contactVC.tag = 2;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVC];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
    
}


@end
