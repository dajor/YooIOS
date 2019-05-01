//
//  SettingsVC.m
//  Yoo
//
//  Created by Arnaud on 07/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "SettingsVC.h"
#import "ChatTools.h"
#import "UserDAO.h"
#import "ChatDAO.h"
#import "RegisterVC.h"
#import "YooUser.h"
#import "ImageTools.h"
#import "FacebookUtils.h"
#import "ValidationTools.h"
#import "ContactDAO.h"
#import "GroupDAO.h"
#import "AboutVC.h"
#import "BackgroundVC.h"
#import "UITools.h"

@implementation SettingsVC

- (id)init {
    self = [super initWithTitle:NSLocalizedString(@"SETTINGS", nil)];
    [[ChatTools sharedInstance] addListener:self];
    [[FacebookUtils sharedInstance] addListener:self];
    self.me = nil;
    self.fbId = nil;
    self.fbPicture = nil;
    self.settings = @[@[@"USER_NICKNAME", @"USER_STATUS"], @[@"APP_BACKGROUND"], @[@"STATS_MESSAGES", @"STATS_NETWORK"]];
    
    self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rightBtn setImage:[UIImage imageNamed:@"info-64.png"] forState:UIControlStateNormal];
    [self.rightBtn addTarget:self action:@selector(showAbout) forControlEvents:UIControlEventTouchUpInside];
    
    
    return self;
}

- (void)dealloc {
    [[FacebookUtils sharedInstance] removeListener:self];
    [[ChatTools sharedInstance] removeListener:self];
}

- (void)update {
    NSString *login = [[NSUserDefaults standardUserDefaults] stringForKey:@"login"];
    self.me = [UserDAO find:login domain:YOO_DOMAIN];
    [self updatePicture];
    [self.tableView reloadData];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];    
    [self update];
}

- (void)updatePicture {
    UIImage *image = nil;
    if (self.me.picture != nil) {
        image = [UIImage imageWithData:self.me.picture];
    } else {
        image = [UIImage imageNamed:@"user-icon.png"];
    }
    CGFloat width = image.size.width * 72 / image.size.height;
    [self.picture setFrame:CGRectMake((self.view.frame.size.width - width) / 2, 8, width, 72)];
    self.picture.layer.cornerRadius = 36;
    self.picture.layer.masksToBounds = YES;
    [self.picture setImage:image];
}

- (void)loadView {
    
    [super loadView];
    
    self.tableView = [[UITableView alloc] initWithFrame:[self contentRect] style:UITableViewStyleGrouped];
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 88)];
    self.picture = [[UIImageView alloc] init];
    [self.picture setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin];
    [header addSubview:self.picture];
    [self.tableView setTableHeaderView:header];
    [self updatePicture];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changePicture)];
    singleTap.numberOfTapsRequired = 1;
    self.picture.userInteractionEnabled = YES;
    [self.picture addGestureRecognizer:singleTap];

    UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [resetBtn setFrame:CGRectMake(0, 0, 160, 40)];
    [resetBtn addTarget:self action:@selector(resetClick) forControlEvents:UIControlEventTouchUpInside];
    [resetBtn setTitle:NSLocalizedString(@"RESET_ALL", nil) forState:UIControlStateNormal];
    [resetBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.tableView setTableFooterView:resetBtn];
    
}


- (void)changePicture {
    if (self.me == nil) return;
    //[ImageTools show:self edit:YES];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    [actionSheet setDelegate:self];
    [actionSheet setTitle:NSLocalizedString(@"CHANGE_PICTURE", nil)];
    self.pictureOptions = [NSMutableArray array];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self.pictureOptions addObject:@"TAKE_PICTURE"];
    }
    [self.pictureOptions addObject:@"PHOTO_LIBRARY"];
    if (self.fbPicture != nil) {
        [self.pictureOptions addObject:@"FACEBOOK_PROFILE"];
    }
    for (NSString *option in self.pictureOptions) {
        [actionSheet addButtonWithTitle:NSLocalizedString(option, nil)];
    }
    [actionSheet addButtonWithTitle:NSLocalizedString(@"CANCEL", nil)];
    [actionSheet setCancelButtonIndex:self.pictureOptions.count];
    [actionSheet showFromRect:self.picture.frame inView:self.view animated:YES];
}


- (void)resetClick {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"RESET_ALL", nil) message:NSLocalizedString(@"CONFIRM_RESET", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:NSLocalizedString(@"RESET_ALL", nil), nil];
    [alert setTag:0];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) {
        if (buttonIndex == 1) {
            [self resetAll];
        }
    } else if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            NSString *newNickname = [[alertView textFieldAtIndex:0] text];
            NSString *error = [ValidationTools validateNickname:newNickname];
            if (error == nil) {
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:newNickname forKey:@"nickname"];
                self.me.alias = newNickname;
                [UserDAO upsert:self.me];
                [[ChatTools sharedInstance] setNickname:newNickname picture:self.me.picture];
                [self update];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WRONG_NICKNAME", nil) message:error delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert setTag:2];
                [alert show];

            }
        }
    }
}

- (void)resetAll {
    
    [[ChatTools sharedInstance] disconnect];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:@"" forKey:@"login"];
    [userDefaults setValue:@"" forKey:@"password"];
    [userDefaults setValue:@"" forKey:@"nickname"];
    [userDefaults setValue:@"" forKey:@"countryCode"];
    [ChatDAO purge];
    [UserDAO purge];
    //[ContactDAO purge]; // no need of removing them
    [GroupDAO purge];
    
    RegisterVC *registerVC = [[RegisterVC alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:registerVC];
    [nav setNavigationBarHidden:YES];
    [self.navigationController presentViewController:nav animated:NO completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
    NSArray *sectionData = [self.settings objectAtIndex:indexPath.section];
    NSString *txt = [sectionData objectAtIndex:indexPath.row];
    [cell.textLabel setText:NSLocalizedString(txt, nil)];
    cell.textLabel.numberOfLines = 1;
    cell.textLabel.textColor = [UITools greenColor];
    [cell setAccessoryType:UITableViewCellAccessoryNone];
    [cell.detailTextLabel setFont:[UIFont fontWithName:@"Avenir-Medium" size:[UIFont systemFontSize] + (indexPath.section == 2 ? 0 : 4)]];
    [cell.textLabel setFont:[UIFont fontWithName:@"Avenir" size:[UIFont systemFontSize]]];
    
    cell.detailTextLabel.numberOfLines = 2;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *value = nil;
    if ([txt isEqualToString:@"USER_NICKNAME"]) {
        value = [userDefaults stringForKey:@"nickname"];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    } else if ([txt isEqualToString:@"USER_STATUS"]) {
        value = [[ChatTools sharedInstance] getStatus];
    } else if ([txt isEqualToString:@"STATS_NETWORK"]) {
        UInt64 received = [[ChatTools sharedInstance] stats:NO];
        UInt64 sent = [[ChatTools sharedInstance] stats:NO];
        value = [NSString stringWithFormat:NSLocalizedString(@"STATS_BYTES_FORMAT", nil), received, sent];

    } else if ([txt isEqualToString:@"STATS_MESSAGES"]) {
        if (self.me != nil) {
            NSInteger received = [ChatDAO countReceived:self.me];
            NSInteger sent = [ChatDAO countSent:self.me];
            value = [NSString stringWithFormat:NSLocalizedString(@"STATS_MESSAGES_FORMAT", nil), (long)received, (long)sent];
        }
    } else if ([txt isEqualToString:@"APP_BACKGROUND"]) {
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        value = [self getBackgroundName:[userDefaults stringForKey:@"background"]];
    }
    [cell.detailTextLabel setText:value];
    
    
    return cell;
}


- (NSString *)getBackgroundName:(NSString *)imgName {
    if ([imgName isEqualToString:@"bg1.png"]) {
        return @"Default";
    } else if ([imgName isEqualToString:@"bg2.png"]) {
        return @"Space";
    } else if ([imgName isEqualToString:@"bg3.png"]) {
        return @"Blue";
    } else if ([imgName isEqualToString:@"bg4.png"]) {
        return @"Grass";
    } else if ([imgName isEqualToString:@"bg5.png"]) {
        return @"Sand";
    } else if ([imgName isEqualToString:@"bg6.png"]) {
        return @"Snow";
    } else if ([imgName isEqualToString:@"bg7.png"]) {
        return @"Lava";
    } else if ([imgName isEqualToString:@"bg8.png"]) {
        return @"Wood";
    } else if ([imgName isEqualToString:@"bg9.png"]) {
        return @"Trees";
    } else {
        return imgName;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.settings.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.settings objectAtIndex:section] count];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && indexPath.row == 0) { // change nickname
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"NICKNAME_CHANGE_TITLE", nil) message:NSLocalizedString(@"NICKNAME_CHANGE_PROMPT", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:NSLocalizedString(@"SAVE", nil), nil];
        [alert setTag:1];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [[alert textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [[alert textFieldAtIndex:0] setReturnKeyType:UIReturnKeyDone];
        [alert show];
    } else if (indexPath.section == 1 && indexPath.row == 0) { // change background
        BackgroundVC *bgVC = [[BackgroundVC alloc] init];
        [self.navigationController pushViewController:bgVC animated:YES];
    }
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [ImageTools handleImageData:info];
    NSData *data = [ImageTools cropImage:image];
    
    [self setProfilePicture:data];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setProfilePicture:(NSData *)data {
    self.me.picture = data;
    [UserDAO upsert:self.me];
    [self updatePicture];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [[ChatTools sharedInstance] setNickname:[userDefaults stringForKey:@"nickname"] picture:data];
}

- (void)lastOnlineChanged:(YooUser *)friend {
    // do nothing
}

// chat events
- (void)friendListChanged:(NSArray *)newFriends {
    for (YooUser *user in newFriends) {
        if ([user isMe]) {
            [self update];
            break;
        }
    }
}

- (void)didReceiveMessage:(YooMessage *)message {
    
}

- (void)didLogin:(NSString *)error {
    [self update];
}

- (void)didReceiveRegistrationInfo:(NSDictionary *)info {
}

- (void)didReceiveUserFromPhone:(NSDictionary *)info {
}

- (void)addressBookChanged {
}

- (void)handlePhoneCall:(CallInfo *)status {
}


// Fb events
- (void)fbInitComplete:(BOOL)success {
    if (success) {
        [[FacebookUtils sharedInstance] getUserInfo];
    }
}
- (void)fbGetUserInfo:(NSDictionary *)info {
    self.fbId = [info objectForKey:@"id"];
    [[FacebookUtils sharedInstance] getPicture:self.fbId];
}
- (void)fbGetFriends:(NSDictionary *)friends {
    
}
- (void)fbGetPicture:(NSDictionary *)picture {
    self.fbPicture = [ImageTools cropImage:[picture objectForKey:@"picture"]];
}

// Action sheet events
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == self.pictureOptions.count) return; // cancel button
    NSString *action = [self.pictureOptions objectAtIndex:buttonIndex];
    if ([action isEqualToString:@"TAKE_PICTURE"]) {
        [ImageTools getPhoto:self edit:YES source:UIImagePickerControllerSourceTypeCamera];
    } else if ([action isEqualToString:@"PHOTO_LIBRARY"]) { // photo library
        [ImageTools getPhoto:self edit:YES source:UIImagePickerControllerSourceTypePhotoLibrary];
    } else if ([action isEqualToString:@"FACEBOOK_PROFILE"]) {
        [self setProfilePicture:self.fbPicture];
    }
}

// Bug fix for 
//- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
//{
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
//}

- (void)showAbout {
    AboutVC *about = [[AboutVC alloc] init];
    [self.navigationController pushViewController:about animated:YES];
}


@end
