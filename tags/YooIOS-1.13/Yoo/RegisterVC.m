//
//  RegisterVC.m
//  Yoo
//
//  Created by Arnaud on 31/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "RegisterVC.h"
#import "LocationTools.h"
#import "CountryPicklistVC.h"
#import "UITools.h"
#import "NBPhoneNumberUtil.h"
#import "ChatTools.h"
#import "UserDAO.h"
#import "YooUser.h"
#import "FacebookUtils.h"
#import "ValidationTools.h"
#import "NBPhoneNumber.h"
#import "ChatListVC.h"
#import "IIViewDeckController.h"    
#import "MenuVC.h"

@implementation RegisterVC

- (id)init {
    self = [super initWithTitle:nil];


    self.phone = @"";
    self.nickname = @"";
    self.code = @"";
    self.smsSent = nil;
    self.login = nil;
    self.step = REGISTER_NICKNAME;
    [[LocationTools sharedInstance] getCountryCode:self];
    self.txtField = [[UITextField alloc] init];
    [self.txtField setFont:[UIFont fontWithName:@"Avenir" size:[UIFont buttonFontSize]]];
    self.txtField.delegate = self;
    [self.txtField addTarget:self action:@selector(textChange:) forControlEvents:UIControlEventEditingChanged];
    [[ChatTools sharedInstance] addListener:self];
    [[ChatTools sharedInstance] login:REGISTRATION_USER password:REGISTRATION_USER];
    [[FacebookUtils sharedInstance] addListener:self];
    self.countryCodeNumber = -1;
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [self.txtField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.01];

}


- (void)dealloc {
    [[FacebookUtils sharedInstance] removeListener:self];
    [[ChatTools sharedInstance] removeListener:self];
}

- (void)loadView {
    
    [super loadView];
    
    self.tableView = [[UITableView alloc] initWithFrame:[self contentRect] style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [self.view addSubview:self.tableView];
    
    //UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 54)];
    [self.titleView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    self.registerBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.registerBtn setTitle:NSLocalizedString(@"NEXT", nil) forState:UIControlStateNormal];
    [self.registerBtn.titleLabel setFont:[UIFont fontWithName:@"Avenir" size:[UIFont buttonFontSize]]];
    [self.registerBtn setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin];
    [self.registerBtn setFrame:CGRectMake(self.view.frame.size.width-90, 0, 100, 44)];
    //[self.registerBtn setFrame:CGRectMake(self.view.frame.size.width/2 + 4, 10, self.view.frame.size.width/2 - 8, 44)];
    [self.registerBtn addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
    [self.registerBtn setEnabled:NO];
    [self.registerBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.titleView addSubview:self.registerBtn];
    
    self.backBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.backBtn setTitle:NSLocalizedString(@"GO_BACK", nil) forState:UIControlStateNormal];
    [self.backBtn.titleLabel setFont:[UIFont fontWithName:@"Avenir" size:[UIFont buttonFontSize]]];
    [self.backBtn setFrame:CGRectMake(0, 0, 100, 44)];
    [self.backBtn addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.backBtn setHidden:YES];
    [self.backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.titleView addSubview:self.backBtn];
    
    self.stepView = [[UIView alloc] initWithFrame:CGRectMake((self.titleView.frame.size.width-40)/2, 0, 60, 10)];
    
    //self.tableView.tableFooterView = footer;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.step == REGISTER_NICKNAME) {
        return NSLocalizedString(@"REGISTER_ENTER_NICKNAME", nil);
    } else if (self.step == REGISTER_PHONE) {
        if (section == 0) return NSLocalizedString(@"REGISTER_ENTER_COUNTRY", nil);
        return NSLocalizedString(@"REGISTER_ENTER_PHONE", nil);
    } else {
        return NSLocalizedString(@"REGISTER_ENTER_CODE", nil);
        
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    for (UIView *child in [cell.contentView subviews]) {
        [child removeFromSuperview];
    }
    [cell.textLabel setFont:[UIFont fontWithName:@"Avenir" size:[UIFont buttonFontSize]]];
    if ((self.step == REGISTER_PHONE && indexPath.section == 1) || (self.step == REGISTER_CODE && indexPath.section == 0)
         || (self.step == REGISTER_NICKNAME && indexPath.section == 0)) {
        [self.txtField setFrame:CGRectInset(cell.contentView.frame, 8, 8)];
        [cell.contentView addSubview:self.txtField];
        [cell.textLabel setText:nil];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    } else if (self.step == REGISTER_PHONE && indexPath.section == 0) {
        NSString *country = [[NSLocale systemLocale] displayNameForKey:NSLocaleCountryCode value:self.countryCode];
        [cell.textLabel setText:country];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        
    }
    return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.step == REGISTER_PHONE) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (void)setCountry:(NSString *)country {
    self.countryCode = country;
    if (self.step == REGISTER_PHONE) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.step == REGISTER_PHONE && indexPath.section == 0) {
        CountryPicklistVC *countryVC = [[CountryPicklistVC alloc] initWithCurrent:self.countryCode listener:self];
        [self.navigationController pushViewController:countryVC animated:YES];
    }
}

- (void)didSelect:(NSArray *)values tag:(NSInteger)tag {
    [self setCountry:[values objectAtIndex:0]];
}

- (void)textChange:(id)sender {
    switch (self.step) {
        case REGISTER_NICKNAME:
            self.nickname = self.txtField.text;
            break;
        case REGISTER_PHONE:
            self.phone = self.txtField.text;
            break;
        default:
            self.code = self.txtField.text;
            break;
    }
    self.txtField.rightView = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.step == REGISTER_NICKNAME) {
        [self next];
    }
    return NO;
}


- (void)goBack {
    self.txtField.rightView = nil;
    self.step--;
    [self buildTitle];
    [self.txtField resignFirstResponder];
    if (self.step == REGISTER_PHONE) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
    } else if (self.step == REGISTER_NICKNAME) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
    }
    [self.txtField becomeFirstResponder];
}



- (void)next {
    self.txtField.rightView = nil;
    if (self.step == REGISTER_CODE) {
        if (self.code.length != 4) {
            [self setTextFieldError:NSLocalizedString(@"WRONG_CODE", nil)];
        } else {
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [[ChatTools sharedInstance] registerUser:self.smsSent code:self.code];
        }
    }
    if (self.step == REGISTER_PHONE) {
        NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
        
        NSError *aError = nil;
        NBPhoneNumber *myNumber = [phoneUtil parse:self.txtField.text defaultRegion:self.countryCode.lowercaseString error:&aError];
        if (aError == nil) {
            // Should check error
            if (![phoneUtil isValidNumber:myNumber]) {

                [self setTextFieldError:NSLocalizedString(@"WRONG_NUMBER", nil)];
            } else {
                NSString *formattedNum = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164
                                                                             error:&aError];
                if ([formattedNum hasPrefix:@"+"]) {
                    formattedNum = [formattedNum substringFromIndex:1];
                }
                if (![self.smsSent isEqualToString:formattedNum]) {
                    [[ChatTools sharedInstance] registerUser:self.nickname phone:formattedNum countryCode:myNumber.countryCode];
                    self.countryCodeNumber = myNumber.countryCode;
                    self.smsSent = formattedNum;
                }
                self.step = REGISTER_CODE;
                [self buildTitle];
                [self.txtField resignFirstResponder];
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationLeft];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
                [self.txtField becomeFirstResponder];

            }
        } else {
            [self setTextFieldError:NSLocalizedString(@"WRONG_NUMBER", nil)];
            NSLog(@"Error : %@", [aError localizedDescription]);
        }
    } else if (self.step == REGISTER_NICKNAME) {
        NSString *error = [ValidationTools validateNickname:self.nickname];
        if (error != nil) {
            [self setTextFieldError:NSLocalizedString(@"WRONG_NICKNAME", nil)];
        } else {
            self.step = REGISTER_PHONE;
            [self buildTitle];
            [self.txtField resignFirstResponder];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationLeft];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
            [self.txtField becomeFirstResponder];
        }
    }
}

- (void)setTextFieldError:(NSString *)error {
    UILabel *wrongLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 140, 30)];
    [wrongLbl setText:error];
    [wrongLbl setTextColor:[UIColor whiteColor]];
    [wrongLbl setBackgroundColor:[UIColor redColor]];
    [wrongLbl setTextAlignment:NSTextAlignmentCenter];
    [wrongLbl.layer setCornerRadius:4];
    self.txtField.rightView = wrongLbl;
    self.txtField.rightViewMode = UITextFieldViewModeAlways;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self buildTitle];
}

- (void)buildTitle {
    self.menuBtn.hidden = true;
    
    //self.title = [NSString stringWithFormat:NSLocalizedString(@"REGISTER_TITLE", nil), (int)self.step + 1];
    self.title = NSLocalizedString(@"REGISTER_TITLE", nil);
    self.titleLbl.frame = CGRectMake((self.titleView.frame.size.width-self.titleLbl.frame.size.width)/2, -5, self.titleLbl.frame.size.width, self.titleLbl.frame.size.height);
    [self updateHeader];
    for (UIView *tmp in self.titleView.subviews) {
        if (tmp.tag >= 100) {
            [tmp removeFromSuperview];
        }
    }
    
    [self.stepView setFrame:CGRectMake((self.titleView.frame.size.width-40)/2, 0, 60, 10)];
    [self.stepView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin];

    for (int i = 0; i < 3; i++) {
        //UIView *stepView = [[UIView alloc] initWithFrame:CGRectMake((self.titleView.frame.size.width-40)/2 + i * 14, 30, 10, 10)];
        UIView *stepView = [[UIView alloc] initWithFrame:CGRectMake(i * 14, 30, 10, 10)];
        [stepView setBackgroundColor:i <= self.step ? [UIColor whiteColor] : [UITools greenColor]];
        stepView.layer.cornerRadius = 5;
        stepView.layer.borderColor = [UIColor whiteColor].CGColor;
        stepView.layer.borderWidth = 1;
        stepView.tag = 100 + i;
        [self.stepView addSubview:stepView];
    }
    [self.titleView addSubview:self.stepView];
    
    [self.backBtn setHidden:self.step == 0];
    if (self.step == REGISTER_NICKNAME) {
        self.txtField.keyboardType = UIKeyboardTypeDefault;
        self.txtField.spellCheckingType = UITextSpellCheckingTypeNo;
        self.txtField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        self.txtField.returnKeyType = UIReturnKeyDone;
    } else {
        self.txtField.keyboardType = UIKeyboardTypePhonePad;
    }
    if (self.step == REGISTER_NICKNAME) {
        [self.txtField setText:self.nickname];
    } else if (self.step == REGISTER_PHONE) {
        [self.txtField setText:self.phone];
    } else if (self.step == REGISTER_CODE) {
        [self.txtField setText:self.code];
    }
}

- (void)lastOnlineChanged:(YooUser *)friend {
    // do nothing
}

- (void)friendListChanged:(NSArray *)newFriends {
    // do nothing
}

- (void)didReceiveMessage:(YooMessage *)message {
    // do nothing
}


- (void)addressBookChanged {
    // do nothing
}

- (void)didLogin:(NSString *)error {
    if (error == nil) {
        if ([[ChatTools sharedInstance].login isEqualToString:REGISTRATION_USER]) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self.registerBtn setEnabled:YES];
        } else {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            ChatListVC *chatVC = [[ChatListVC alloc] init];
            MenuVC *menuVC = [[MenuVC alloc] init];
            UINavigationController *navCon = [[UINavigationController alloc] initWithRootViewController:chatVC];
            [navCon setNavigationBarHidden:YES];
            IIViewDeckController *deckController = [[IIViewDeckController alloc] initWithCenterViewController:navCon leftViewController:menuVC rightViewController:nil];
            [deckController setRightSize:0];
            [self.navigationController pushViewController:deckController animated:YES];
            //[self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)didReceiveRegistrationInfo:(NSDictionary *)info {
    if (info == nil) {
        if (self.step == REGISTER_CODE) {
            [self setTextFieldError:NSLocalizedString(@"WRONG_CODE", nil)];
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        return;
    }
    NSString *key = [[info allKeys] objectAtIndex:0];
    NSString *value = [info objectForKey:key];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([key isEqualToString:@"password"]) {
        [[ChatTools sharedInstance] logout];
        [userDefaults setObject:self.nickname forKey:@"nickname"];
        [userDefaults setObject:self.login forKey:@"login"];
        [userDefaults setObject:value forKey:@"password"];
        [userDefaults setObject:self.countryCode forKey:@"countryCode"];
        [userDefaults setInteger:self.countryCodeNumber forKey:@"callingCode"];
        [[ChatTools sharedInstance] login:self.login password:value];
        //[TestFlight passCheckpoint:@"REGISTRATION_COMPLETE"];
        // create user
        YooUser *yooUser = [[YooUser alloc] initWithName:self.login domain:YOO_DOMAIN];
        yooUser.alias = self.nickname;
        yooUser.callingCode = self.countryCodeNumber;
        [UserDAO upsert:yooUser];

    } else if ([key isEqualToString:@"username"]) {
        self.login = value;
    }
}


- (void)didReceiveUserFromPhone:(NSDictionary *)info {
    // do nothing
}

- (void)didCallSendOutMessage {
}


- (void)fbInitComplete:(BOOL)success {
    if (success) {
        [[FacebookUtils sharedInstance] getUserInfo];
    }
}

- (void)fbGetUserInfo:(NSDictionary *)info {
    if (self.step == REGISTER_NICKNAME && self.txtField.text.length == 0) {
        self.nickname = [info objectForKey:@"name"];
        [self.txtField setText:self.nickname];
    }
}

- (void)fbGetFriends:(NSDictionary *)friends {
    
}
- (void)fbGetPicture:(NSDictionary *)picture {
    
}


@end
