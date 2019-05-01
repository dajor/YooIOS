//
//  FacebookUtils.h
//  OneXTwo
//
//  Created by Arnaud on 28/10/13.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>
#import "FacebookListener.h"

@interface FacebookUtils : NSObject

@property (nonatomic, retain) ACAccount *facebookAccount;
@property (nonatomic, retain) NSMutableArray *listeners;


+ (FacebookUtils *)sharedInstance;
- (void)getUserInfo;
- (void)getFriends;
- (void)getPicture:(NSString *)fbId;
- (void)addListener:(NSObject <FacebookListener> *)listener;
- (void)removeListener:(NSObject <FacebookListener> *)listener;


@end
