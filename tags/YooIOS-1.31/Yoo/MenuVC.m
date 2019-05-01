//
//  MenuVC.m
//  Yoo
//
//  Created by Vanroth on 2/17/15.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import "MenuVC.h"
#import "IIViewDeckController.h"
#import "UITools.h"
#import "ContactListVC.h"
#import "ChatListVC.h"
#import "SettingsVC.h"  
#import "ChatDAO.h"
#import "ChatTools.h"
#import "ActivityTools.h"
#import "UserDAO.h"
#import "ImageTools.h"
#import "ChatVC.h"
#import "MenuCell.h"

@interface MenuVC ()

@end

@implementation MenuVC


- (id)init {
    self = [super init];
    if (self) {
        self.options = [NSArray arrayWithObjects:@"CHAT_LIST", @"CONTACT_LIST", nil];
        self.icons = [NSArray arrayWithObjects:@"chat-64.png", @"contacts-64.png",nil];
    }
    [[ChatTools sharedInstance] addListener:self];
    return self;
}

- (void)loadView {
    
    UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 400)];
    [mainView setBackgroundColor:[UITools menuBackgroundColor]];//[UIColor colorWithRed:96/255 green:96/255 blue:96/255 alpha:1]];
    
    headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    [headerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    headerView.backgroundColor = [UITools menuBackgroundColor];//[UIColor colorWithRed:0.30 green:0.38 blue:0.13 alpha:1];
    [mainView addSubview:headerView];
    
    //UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tab_chat.png"]];
    //[logo setFrame:CGRectMake(7, 2, 190, 77)];
    //[headerView addSubview:logo];
    
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, 320, 380)];
    [self.tableView setBackgroundColor:[UITools menuBackgroundColor]];
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [mainView addSubview:self.tableView];
    
    selectedIndex = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView selectRowAtIndexPath:selectedIndex animated:YES scrollPosition:UITableViewScrollPositionBottom];
    
    [self setView:mainView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.activity = [ActivityTools getActivity];
    self.recipients = [self.activity flatten];
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:selectedIndex animated:YES scrollPosition:UITableViewScrollPositionBottom];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        return 40;
    } else {
        return 49;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.recipients.count > 0 ? 3 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return [self.options count];
    } else {
        return MIN(6, [self.recipients count]);
    }
}


//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    if (section == 0) {
//        return nil; //NSLocalizedString(@"SETTINGS", nil);
//    } else if (section == 1) {
//        return NSLocalizedString(@"CHATS", nil);
//    } else {
//        return NSLocalizedString(@"RECENT", nil);
//    }
//}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return section == 2 ? 56 : 16;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, [self tableView:tableView heightForHeaderInSection:section])];
    if (section == 2) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(8, 36, header.frame.size.width - 16, 20)];
        [label setText:NSLocalizedString(@"RECENT", nil)];
        [label setFont:[UIFont fontWithName:@"Avenir" size:14]];
        [label setTextColor:[UIColor grayColor]];
        [header addSubview:label];
    }

    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier1 = @"MenuCell";
    UITableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier1];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier1];
        UIView *bg = [[UIView alloc] init];
        [bg setBackgroundColor: [UITools greenColor]];
        cell.selectedBackgroundView = bg;
    }
    
    cell.backgroundColor = [UIColor clearColor];
    
    
    // Clear contentview before adding stuff ! because cells are reused
    for (UIView *tmpView in cell.contentView.subviews) {
        [tmpView removeFromSuperview];
    }
    
    UIFont* font = [UIFont fontWithName:@"Avenir" size:18];
    cell.textLabel.font = font;
    if (![UITools isIOS7]) {
        cell.textLabel.backgroundColor = [UITools menuBackgroundColor]; // fixes a display bug on iOS6
    }
    cell.textLabel.textColor = [UIColor whiteColor];
    if (indexPath.section == 0) {
        YooUser *currentUser = [UserDAO find:[ChatTools sharedInstance].login domain:YOO_DOMAIN];
        [cell.textLabel setText:currentUser.alias];
        UIImage *image = nil;
        if (currentUser.picture != nil) {
            image = [UIImage imageWithData:currentUser.picture];
        } else {
            image = [UIImage imageNamed:@"user-icon.png"];
        }
        cell.imageView.image = [ImageTools makeRoundedImage:[ImageTools resize:image maxWidth:36]];
    } else if (indexPath.section == 1) {
        NSString *item = [self.options objectAtIndex:indexPath.row];
        [cell.textLabel setText:NSLocalizedString(item, nil)];
        cell.imageView.image = [UIImage imageNamed:[self.icons objectAtIndex:indexPath.row]];
        if ([item isEqualToString:@"CHAT_LIST"]) {
            NSInteger unread = [ChatDAO unreadCount];
            if (unread>0) {
                NSString *unreadText = [NSString stringWithFormat:@"%ld", (long)unread];
                UIFont* font2 = [UIFont fontWithName:@"Avenir" size:14];
                self.unReadlbl = [[UILabel alloc] initWithFrame:CGRectMake(224, 17, 22, 22)];
                [self.unReadlbl.layer setCornerRadius:11];
                [self.unReadlbl setTextAlignment:NSTextAlignmentCenter];
                [self.unReadlbl setText:unreadText];
                [self.unReadlbl setTextColor:[UIColor whiteColor]];
                [self.unReadlbl setFont:font2];
                [self.unReadlbl sizeToFit];
                
                CGRect rect = [self.unReadlbl bounds];
                rect.size.width += 10;
                rect.size.height = 22;
                if (rect.size.width<22)rect.size.width = 22;
                rect.origin.y = 17;
                rect.origin.x = 270-rect.size.width;
                self.unReadlbl.frame = rect;
                
                [self.unReadlbl setClipsToBounds:YES];
                [self.unReadlbl setBackgroundColor:[UIColor redColor]];
                [cell.contentView addSubview:self.unReadlbl];
            }
        }

    } else {
        NSArray *tuple = [self.recipients objectAtIndex:indexPath.row];
        YooUser *recipient = [tuple objectAtIndex:0];
        NSString *name;
        if ([recipient isKindOfClass:[YooUser class]]) {
            YooUser *yooUser = (YooUser *)recipient;
            Contact *contact = [self.activity.contactMap objectForKey:[NSString stringWithFormat:@"%ld", (long)yooUser.contactId]];
            name = contact.fullName;
        } else {
            name = ((YooGroup *)recipient).alias;
        }
        [cell.textLabel setText:name];
        [cell.textLabel setTextColor:[UIColor colorWithWhite:0.8 alpha:1]];
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedIndex = indexPath;
    //[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UINavigationController *currentNav = (UINavigationController *)self.viewDeckController.centerController;
    for (UIViewController *tmp in currentNav.viewControllers) {
        [[ChatTools sharedInstance] removeListener:(UIViewController <ChatListener> *)tmp];
    }
    
    UIViewController *newVC = nil;
    if (indexPath.section == 0) {
        newVC = [[SettingsVC alloc] init];
    } else if (indexPath.section == 1) {
        NSString *option = [self.options objectAtIndex:indexPath.row];
        if ([option isEqualToString:@"CHAT_LIST"]) {
            newVC = [[ChatListVC alloc] init];
        } else if ([option isEqualToString:@"CONTACT_LIST"]) {
            newVC = [[ContactListVC alloc] initWithType:clAddressBookList listener:nil title:NSLocalizedString(@"CONTACT_LIST", nil) selected:nil];
        }
    } else if (indexPath.section == 2) {
        NSArray *tuple = [self.recipients objectAtIndex:indexPath.row];
        NSObject<YooRecipient> *recipient = [tuple objectAtIndex:0];
        ChatMode mode;
        if ([recipient isKindOfClass:[YooUser class]]) {
            mode = cmChat;
        } else {
            mode = cmGroup;
        }
        newVC = [[ChatVC alloc] initWithMode:mode recipient:recipient];
    }
    [self.viewDeckController toggleLeftView];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newVC];
    [navController setNavigationBarHidden:YES];
    [self.viewDeckController setCenterController:navController];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.unReadlbl setBackgroundColor:[UIColor redColor]];
}

- (void)didReceiveMessage:(YooMessage *)message {
    NSInteger unread = [ChatDAO unreadCount];
    if (unread > 0) {
        NSString *unreadText = [NSString stringWithFormat:@"%ld", (long)unread];
        [self.unReadlbl setText:unreadText];
    }
}

- (void)didLogin:(NSString *)error {
    
}

- (void)didReceiveRegistrationInfo:(NSDictionary *)info {
}

- (void)didReceiveUserFromPhone:(NSDictionary *)info {
}

- (void)addressBookChanged {
}

- (void)handlePhoneCall:(YooMessage *)call {
}

-(void)friendListChanged:(NSArray *)newFriends
{

}
-(void)lastOnlineChanged:(YooUser *)friends
{

}

@end
