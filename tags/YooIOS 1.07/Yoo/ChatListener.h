//
//  ChatListener.h
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YooMessage.h"

@protocol ChatListener <NSObject>

- (void)friendListChanged:(NSArray *)newFriends;
- (void)didReceiveMessage:(YooMessage *)message;
- (void)didLogin:(NSString *)error;
- (void)didReceiveRegistrationInfo:(NSDictionary *)info;
- (void)didReceiveUserFromPhone:(NSDictionary *)info;
- (void)addressBookChanged;

@end
