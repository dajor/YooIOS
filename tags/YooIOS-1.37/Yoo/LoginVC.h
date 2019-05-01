//
//  LoginVC.h
//  Yoo
//
//  Created by Arnaud on 23/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatListener.h"

@interface LoginVC : UIViewController<UITextFieldDelegate, ChatListener>

@property (nonatomic, retain) UITextField *loginTxt;
@property (nonatomic, retain) UITextField *passwordTxt;

@end
