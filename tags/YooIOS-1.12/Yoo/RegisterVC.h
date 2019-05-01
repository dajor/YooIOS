//
//  RegisterVC.h
//  Yoo
//
//  Created by Arnaud on 31/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocationListener.h"
#import "PicklistListener.h"
#import "ChatListener.h"
#import "MBProgressHUD.h"
#import "FacebookListener.h"
#import "BaseListVC.h"

#define REGISTER_NICKNAME 0
#define REGISTER_PHONE 1
#define REGISTER_CODE 2

@interface RegisterVC : BaseListVC<UITableViewDataSource, UITableViewDelegate, LocationListener, PicklistListener, ChatListener, UITextFieldDelegate, FacebookListener>

@property (nonatomic, retain) NSString *countryCode;
@property (nonatomic, retain) UITextField *txtField;
@property (nonatomic, retain) UIButton *registerBtn;
@property (nonatomic, retain) UIButton *backBtn;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *nickname;
@property (nonatomic, retain) NSString *code;
@property (nonatomic, retain) NSString *smsSent;
@property (nonatomic, retain) NSString *login;
@property (assign) NSInteger step;
@property (assign) int countryCodeNumber;
@end
