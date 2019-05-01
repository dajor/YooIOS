//
//  ContactDetailVC.m
//  Yoo
//
//  Created by Arnaud on 06/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "ContactDetailVC.h"
#import "Contact.h"
#import "LabelledValue.h"
#import "UserDAO.h"
#import "ChatVC.h"
#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "ContactManager.h"
#import "UITools.h"
#import "ChatTools.h"

@implementation ContactDetailVC

- (id)initWithContact:(NSInteger)contactId {
    self = [super initWithTitle:nil];
    self.contact = [[ContactManager sharedInstance] find:contactId];
    self.showButtons = YES;
    self.title = self.contact.fullName;
    NSMutableArray *tmp = [NSMutableArray array];
    for (YooUser *yooUser in [UserDAO list]) {
        if (yooUser.contactId == contactId) {
            [tmp addObject:yooUser];
        }
    }
    [[ChatTools sharedInstance] addListener:self];
    self.yooUsers = tmp;
    if([self.yooUsers count] == 1 && ![self onlineUser])[[ChatTools sharedInstance] lastPresence:((YooUser *)self.yooUsers[0]).toJID];
    
    return self;
}

- (void)dealloc {
    [[ChatTools sharedInstance] removeListener:self];
}

- (void)updateImage {
    NSData *pictureData = nil;
    for (YooUser *yooUser in self.yooUsers) {
        if ([yooUser.picture length] > 0) {
            pictureData = yooUser.picture;
        }
    }
    UIImage *image = nil;
    if (pictureData != nil) {
        image = [UIImage imageWithData:pictureData];
    } else {
        image = [UIImage imageNamed:@"user-icon.png"];
    }
    [self.picture setImage:image];
}


- (void)loadView {
    [super loadView];
    
    self.tableView = [[UITableView alloc] initWithFrame:[self contentRect] style:UITableViewStyleGrouped];
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    // build header
    NSMutableArray *components = [NSMutableArray array];
    NSInteger y = 0;
    BOOL isMe = NO;
    for (YooUser *yooUser in self.yooUsers) {
        if ([yooUser isMe]) {
            isMe = YES;
        }
    }
    self.picture = [[UIImageView alloc] init];
    [self.picture setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin];
    [self.picture setContentMode:UIViewContentModeScaleAspectFill];
    [self.picture setFrame:CGRectMake((self.view.frame.size.width - 120) / 2, y + 8, 120, 120)];
    self.picture.layer.cornerRadius = 60;
    self.picture.layer.masksToBounds = YES;
    
    BOOL isPresent = [self onlineUser];
    if ([self.yooUsers count] > 0) {
        self.picture.layer.borderColor = [[UITools greenColor] CGColor];
        self.picture.layer.borderWidth = 5;
    }

    
    [self updateImage];
    [components addObject:self.picture];
    y += 136;
    
    if (!isPresent && [self.yooUsers count]>0) {
        self.picture.layer.borderColor = [[UIColor darkGrayColor] CGColor];
        lastOnline = [[UILabel alloc] initWithFrame:CGRectMake(50, y, self.titleView.frame.size.width - 100, 18)];
        
        if ([self.yooUsers count] == 1) {
            [lastOnline setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
            [lastOnline setFont:[UIFont fontWithName:@"Avenir" size:12]];
            [lastOnline setTextColor: [UIColor colorWithWhite:0 alpha:0.5] ];
            [lastOnline setTextAlignment:NSTextAlignmentCenter];
            NSString *onlineStatus = [UITools lastOnlineDisplay:(YooUser *)self.yooUsers[0]];
            [lastOnline setText:onlineStatus];
            [components addObject:lastOnline];
            y+=18;
            
        }
        
    }
    
    if ([self.yooUsers count] == 0) {
        BOOL inviteBtn = NO;
        if (self.contact.phones.count > 0 && [MFMessageComposeViewController canSendText]) {
            UIButton *smsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [smsButton setFrame:CGRectMake(0, y, (self.view.frame.size.width/2)-44, 44)];
            [smsButton setTitle:NSLocalizedString(@"INVITE_BY_SMS", nil) forState:UIControlStateNormal];
            //[smsButton setBackgroundColor:[UIColor purpleColor]];
            [smsButton addTarget:self action:@selector(inviteSMS) forControlEvents:UIControlEventTouchUpInside];
            [smsButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
            [components addObject:smsButton];
            inviteBtn = YES;
        }
        if (self.contact.emails.count > 0 && [MFMailComposeViewController canSendMail]) {
            UIButton *mailButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [mailButton setFrame:CGRectMake((self.view.frame.size.width/2)+44, y, (self.view.frame.size.width/2)-44, 44)];
            [mailButton setTitle:NSLocalizedString(@"INVITE_BY_EMAIL", nil) forState:UIControlStateNormal];
            [mailButton addTarget:self action:@selector(inviteEmail) forControlEvents:UIControlEventTouchUpInside];
            [mailButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
            [components addObject:mailButton];
            inviteBtn = YES;
        }
        if (inviteBtn) {
            y += 52;
        }
    } else {
        if (self.showButtons) {
            // add buttons to call / chat
            UIView *buttonView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 160, y - 88, 320, 48)];
            [buttonView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
            
            UIButton *callBtn = [[UIButton alloc] initWithFrame:CGRectMake(36, 0, 48, 48)];
            [callBtn setImage:[UIImage imageNamed:@"phone-48.png"] forState:UIControlStateNormal];
            [callBtn setTag:2];
            [callBtn addTarget:self action:@selector(startChat:) forControlEvents:UIControlEventTouchUpInside];
            [buttonView addSubview:callBtn];
            
            UIButton *chatBtn = [[UIButton alloc] initWithFrame:CGRectMake(236, 0, 48, 48)];
            [chatBtn setImage:[UIImage imageNamed:@"bubble-64.png"] forState:UIControlStateNormal];
            [chatBtn setTag:1];
            [chatBtn addTarget:self action:@selector(startChat:) forControlEvents:UIControlEventTouchUpInside];
            [buttonView addSubview:chatBtn];
            
            [components addObject:buttonView];
        }
    }
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, y)];
    for (UIView *comp in components) {
        [header addSubview:comp];
    }
    [self.tableView setTableHeaderView:header];
    
}
- (void)inviteEmail {
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    [controller setSubject:NSLocalizedString(@"INVITE_TITLE", nil)];
    LabelledValue *firstEmail = [self.contact.emails objectAtIndex:0];
    [controller setToRecipients:@[firstEmail.value]];
    [controller setMessageBody:NSLocalizedString(@"INVITE_BODY", nil) isHTML:YES];
    [controller setMailComposeDelegate:self];
    [self presentViewController:controller animated:YES completion:nil];
}

-(BOOL)onlineUser{
    for (YooUser *yooUser in self.yooUsers) {
        if(![yooUser isMe]){
            BOOL isPresent  =[[ChatTools sharedInstance] isPresent:yooUser] ;
            if ( isPresent)return isPresent;
        }
    }
    return false;
}

- (void)inviteSMS {
    self.smsController = [[MFMessageComposeViewController alloc] init];
	if ([MFMessageComposeViewController canSendText]) {
        [self.smsController setBody:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"INVITE_TITLE", nil), NSLocalizedString(@"INVITE_BODY", nil)]];
        LabelledValue *phone = [self getPhone:self.contact.phones];
        [self.smsController setRecipients:@[phone.value]];
		[self.smsController setMessageComposeDelegate:self];
		[self presentViewController:self.smsController animated:YES completion:nil];
	}
}

-(LabelledValue *)getPhone:(NSArray *)phones{
    LabelledValue *phone = [phones objectAtIndex:0];
    LabelledValue *mobile = nil;
    LabelledValue *iphone = nil;
    if([phones count] > 1){
        for (LabelledValue *p in phones) {
            if ([[p.label lowercaseString] isEqualToString:@"mobile"]) {
                mobile = p;
            }
            if ([[p.label lowercaseString] isEqualToString:@"iphone"]) {
                iphone = p;
            }
        }
    }
    
    if (mobile) phone  = mobile;
    else if(iphone) phone  = iphone;
    return phone;
}

- (void)startChat:(id)sender {
    if (self.yooUsers.count == 1) {
        YooUser *yooUser = [self.yooUsers objectAtIndex:0];
        ChatVC *chatVC = [[ChatVC alloc] initWithMode:cmChat recipient:yooUser];
        chatVC.shouldStartCall = ((UIView *)sender).tag == 2;
        [self.navigationController pushViewController:chatVC animated:YES];
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"CHAT_WITH", nil) delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        actionSheet.tag = ((UIView *)sender).tag;
        for (YooUser *yooUser in self.yooUsers) {
            [actionSheet addButtonWithTitle:yooUser.alias];
        }
        [actionSheet addButtonWithTitle:NSLocalizedString(@"CANCEL", nil)];
        [actionSheet setCancelButtonIndex:[self.yooUsers count]];
        [actionSheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex >= self.yooUsers.count) return;
    YooUser *yooUser = [self.yooUsers objectAtIndex:buttonIndex];
    ChatVC *chatVC = [[ChatVC alloc] initWithMode:cmChat recipient:yooUser];
    chatVC.shouldStartCall = actionSheet.tag == 2;
    [self.navigationController pushViewController:chatVC animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.detailTextLabel setFont:[UIFont fontWithName:@"Avenir-Medium" size:[UIFont systemFontSize] + 2]];
    [cell.textLabel setFont:[UIFont fontWithName:@"Avenir" size:[UIFont systemFontSize]]];
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                [cell.textLabel setText:NSLocalizedString(@"FIRST_NAME", nil)];
                [cell.detailTextLabel setText:self.contact.firstName];
                break;
            case 1:
                [cell.textLabel setText:NSLocalizedString(@"LAST_NAME", nil)];
                [cell.detailTextLabel setText:self.contact.lastName];
                break;
            case 2:
                [cell.textLabel setText:NSLocalizedString(@"COMPANY", nil)];
                [cell.detailTextLabel setText:self.contact.company];
                break;
            case 3:
                [cell.textLabel setText:NSLocalizedString(@"JOB_TITLE", nil)];
                [cell.detailTextLabel setText:self.contact.jobTitle];
                break;
            default:
                break;
        }
    } else if (indexPath.section == 1 || indexPath.section == 2) {
        NSArray *list = indexPath.section == 1 ? self.contact.phones : self.contact.emails;
        LabelledValue *labVal = [list objectAtIndex:indexPath.row];
        [cell.textLabel setText:[labVal.label capitalizedString]];
        [cell.detailTextLabel setText:labVal.value];
    }
    cell.textLabel.textColor = [UITools greenColor];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 25;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return NSLocalizedString(@"CONTACT_DETAILS", nil);
        case 1:
            return NSLocalizedString(@"CONTACT_PHONES", nil);
        default:
            return NSLocalizedString(@"CONTACT_EMAILS", nil);
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 4;
        case 1:
            return self.contact.phones.count;
        default:
            return self.contact.emails.count;
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    switch (result) {
        case MessageComposeResultCancelled:
            NSLog(@"message cancelled");
            break;
        case MessageComposeResultSent:
            NSLog(@"message sent");
            break;
        case MessageComposeResultFailed:
            NSLog(@"cannot send message");
            break;
        default:
            break;
    }
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void)friendListChanged:(NSArray *)newFriends {
    for (YooUser *tmp1 in newFriends) {
        for (YooUser *tmp2 in self.yooUsers) {
            if ([tmp1.toJID isEqualToString:tmp2.toJID]) {
                tmp2.picture = tmp1.picture;
                [self updateImage];
            }
        }
    }
}

- (void)lastOnlineChanged:(YooUser *)friends {
    if (friends.contactId == self.contact.contactId) {
        NSString *onlineStatus = [UITools lastOnlineDisplay:friends];
        [lastOnline setText:onlineStatus];
    }
}
- (void)didReceiveMessage:(YooMessage *)message {}
- (void)didLogin:(NSString *)error {}
- (void)didReceiveRegistrationInfo:(NSDictionary *)info {}
- (void)didReceiveUserFromPhone:(NSDictionary *)info {}
- (void)handlePhoneCall:(YooMessage *)call {}
- (void)addressBookChanged {}

@end
