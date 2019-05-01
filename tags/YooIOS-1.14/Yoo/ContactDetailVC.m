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

@implementation ContactDetailVC

- (id)initWithContact:(NSInteger)contactId {
    self = [super initWithTitle:nil];
    self.contact = [[ContactManager sharedInstance] find:contactId];
    self.title = self.contact.fullName;
    NSMutableArray *tmp = [NSMutableArray array];
    for (YooUser *yooUser in [UserDAO list]) {
        if (yooUser.contactId == contactId) {
            [tmp addObject:yooUser];
        }
    }
    self.yooUsers = tmp;
    self.showChatButton = YES;
    self.showCallButton = YES;
    return self;
}

- (void)updatePicture {

}


- (void)loadView {
    [super loadView];
    
    self.tableView = [[UITableView alloc] initWithFrame:[self contentRect] style:UITableViewStyleGrouped];
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    if ([self.yooUsers count] == 0) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
        if (self.contact.phones.count > 0 && [MFMessageComposeViewController canSendText]) {
            UIButton *smsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [smsButton setFrame:CGRectMake(0, 0, self.view.frame.size.width/2, 44)];
            [smsButton setTitle:NSLocalizedString(@"INVITE_BY_SMS", nil) forState:UIControlStateNormal];
            [smsButton addTarget:self action:@selector(inviteSMS) forControlEvents:UIControlEventTouchUpInside];
            [smsButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
            [headerView addSubview:smsButton];
        }
        if (self.contact.emails.count > 0 && [MFMailComposeViewController canSendMail]) {
            UIButton *mailButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [mailButton setFrame:CGRectMake(self.view.frame.size.width/2, 0, self.view.frame.size.width/2, 44)];
            [mailButton setTitle:NSLocalizedString(@"INVITE_BY_EMAIL", nil) forState:UIControlStateNormal];
            [mailButton addTarget:self action:@selector(inviteEmail) forControlEvents:UIControlEventTouchUpInside];
            [mailButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
            [headerView addSubview:mailButton];
        }
        if (headerView.subviews.count > 0) {
            [self.tableView setTableHeaderView:headerView];
        }
    } else {
        BOOL isMe = NO;
        NSData *pictureData = nil;
        for (YooUser *yooUser in self.yooUsers) {
            if ([yooUser isMe]) {
                isMe = YES;
            }
            if ([yooUser.picture length] > 0) {
                pictureData = yooUser.picture;
            }
        }
        
        /*if(!isMe && self.showCallButton){
            UIBarButtonItem *chatBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(startChat)];
            [self.navigationItem setRightBarButtonItem:chatBtn];
        }
        */
        if (!isMe && self.showChatButton) {
            self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [self.rightBtn setImage:[UIImage imageNamed:@"bubble-64.png"] forState:UIControlStateNormal];
            [self.rightBtn addTarget:self action:@selector(startChat) forControlEvents:UIControlEventTouchUpInside];
        }
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 88)];
        UIImageView *picture = [[UIImageView alloc] init];
        [picture setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin];
        UIImage *image = nil;
        if (pictureData != nil) {
            image = [UIImage imageWithData:pictureData];
        } else {
            image = [UIImage imageNamed:@"user-icon.png"];
        }
        CGFloat width = image.size.width * 80 / image.size.height;
        [picture setFrame:CGRectMake((self.view.frame.size.width - width) / 2, 8, width, 80)];
        [picture setImage:image];
        picture.layer.cornerRadius = 40;
        picture.layer.masksToBounds = YES;
        if(self.yooUsers != nil)
        {
            picture.layer.borderColor = [[UITools greenColor] CGColor];
            picture.layer.borderWidth = 5;
        }
        [header addSubview:picture];
        [self.tableView setTableHeaderView:header];
    }
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

- (void)inviteSMS {
    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
	if ([MFMessageComposeViewController canSendText]) {
        [controller setBody:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"INVITE_TITLE", nil), NSLocalizedString(@"INVITE_BODY", nil)]];
        LabelledValue *firstPhone = [self.contact.phones objectAtIndex:0];
        [controller setRecipients:@[firstPhone.value]];
		[controller setMessageComposeDelegate:self];
		[self presentViewController:controller animated:YES completion:nil];
	}
}

- (void)startChat {
    if (self.yooUsers.count == 1) {
        YooUser *yooUser = [self.yooUsers objectAtIndex:0];
        ChatVC *chatVC = [[ChatVC alloc] initWithMode:cmChat recipient:yooUser];
        [self.navigationController pushViewController:chatVC animated:YES];
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"CHAT_WITH", nil) delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
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
	[self dismissViewControllerAnimated:YES completion:nil];
}


@end
