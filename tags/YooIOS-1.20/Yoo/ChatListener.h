//
//  ChatListener.h
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YooMessage.h"
#import "CallInfo.h"


@protocol ChatListener <NSObject>

- (void)friendListChanged:(NSArray *)newFriends;
- (void)lastOnlineChanged:(YooUser *)friends;
- (void)didReceiveMessage:(YooMessage *)message;
- (void)didLogin:(NSString *)error;
- (void)didReceiveRegistrationInfo:(NSDictionary *)info;
- (void)didReceiveUserFromPhone:(NSDictionary *)info;
- (void)handlePhoneCall:(CallInfo *)call;
- (void)addressBookChanged;

@end
