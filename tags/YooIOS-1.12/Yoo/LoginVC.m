//
//  LoginVC.m
//  Yoo
//
//  Created by Arnaud on 23/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "LoginVC.h"
#import "ChatTools.h"
#import "ChatListVC.h"
#import "MBProgressHUD.h"
#import "UITools.h"

@implementation LoginVC

- (id)init {
    self = [super init];
    self.title = @"YOO";
    [[ChatTools sharedInstance] addListener:self];
    return self;
}


- (void)dealloc {
    [[ChatTools sharedInstance] removeListener:self];
}

- (void)login {
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.labelText = NSLocalizedString(NSLocalizedString(@"CONNECTING", nil), nil);
    
    [[ChatTools sharedInstance] login:[[NSUserDefaults standardUserDefaults] stringForKey:@"login"] password:[[NSUserDefaults standardUserDefaults] stringForKey:@"password"]];
}


- (void)loadView {

    UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 400)];
    [mainView setBackgroundColor:[UIColor whiteColor]];

    int offset = [UITools isIOS7] ? 72 : 0;
    
    
    UILabel *loginLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, offset + 8, 288, 16)];
    loginLbl.backgroundColor = [UIColor clearColor];
    [loginLbl setFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];
    loginLbl.text = NSLocalizedString(@"LOGIN", nil);
    [mainView addSubview:loginLbl];
    
    self.loginTxt = [[UITextField alloc] initWithFrame:CGRectMake(16, offset + 30, 288, 30)];
    self.loginTxt.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.loginTxt.keyboardType = UIKeyboardTypeDefault;
    self.loginTxt.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.loginTxt.autocorrectionType = UITextAutocorrectionTypeNo;
    self.loginTxt.borderStyle = UITextBorderStyleRoundedRect;
    self.loginTxt.placeholder = loginLbl.text;
    self.loginTxt.returnKeyType = UIReturnKeyNext;
    self.loginTxt.delegate = self;
    [self.loginTxt addTarget:self action:@selector(textChange:) forControlEvents:UIControlEventEditingChanged];
    self.loginTxt.tag = 1;
    self.loginTxt.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"login"];
    [mainView addSubview:self.loginTxt];
    
    UILabel *passwordLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, offset + 74, 288, 16)];
    passwordLbl.backgroundColor = [UIColor clearColor];
    [passwordLbl setFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];
    passwordLbl.text = NSLocalizedString(@"PASSWORD", nil);
    [mainView addSubview:passwordLbl];
    
    self.passwordTxt = [[UITextField alloc] initWithFrame:CGRectMake(16, offset + 96, 288, 30)];
    self.passwordTxt.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.passwordTxt.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordTxt.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.passwordTxt.autocorrectionType = UITextAutocorrectionTypeNo;
    self.passwordTxt.secureTextEntry = YES;
    self.passwordTxt.placeholder = passwordLbl.text;
    self.passwordTxt.returnKeyType = UIReturnKeyDone;
    self.passwordTxt.delegate = self;
    [self.passwordTxt addTarget:self action:@selector(textChange:) forControlEvents:UIControlEventEditingChanged];
    self.passwordTxt.tag = 2;
    self.passwordTxt.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"password"];
    [mainView addSubview:self.passwordTxt];
    
    UIButton *loginBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [loginBtn setFrame:CGRectMake(160, offset + 138, 144, 40)];
    [loginBtn setTitle:NSLocalizedString(@"LOGIN", nil) forState:UIControlStateNormal];
    [loginBtn addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:loginBtn];
    
    [self setView:mainView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.loginTxt becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSInteger nextTag = textField.tag + 1;
    // Try to find next responder
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
        // Not found, so remove keyboard.
        [textField resignFirstResponder];
    }
    return NO; // We do not want UITextField to insert line-breaks.
}

- (void)textChange:(id)sender {
    UITextView *textView = (UITextView *)sender;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:textView.text
                     forKey:textView.tag == 1 ? @"login" : @"password"];
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

- (void)didReceiveRegistrationInfo:(NSDictionary *)info {
    // do nothing
}


- (void)didReceiveUserFromPhone:(NSDictionary *)info {
    // do nothing
}

- (void)addressBookChanged {
    // do nothing
}

- (void)didLogin:(NSString *)error {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    if (error == nil) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"LOGIN_ERROR", nil)
                                                        message:error
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}



@end
