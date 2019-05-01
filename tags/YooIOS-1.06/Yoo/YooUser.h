//
//  YooUser.h
//  Yoo
//
//  Created by Arnaud on 16/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YooRecipient.h"

@interface YooUser : NSObject<YooRecipient>

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *domain;
@property (nonatomic, retain) NSString *alias;
@property (assign) NSInteger contactId;
@property (nonatomic, retain) NSData *picture;
@property (nonatomic, retain) NSDate *lastonline;
@property (assign) int callingCode;
@property (nonatomic, retain) NSString *countryCode;

- (id)initWithJID:(NSString *)jid;
- (id)initWithName:(NSString *)pName domain:(NSString *)pDomain;
- (BOOL)isSame:(YooUser *)other;
- (NSString *)toJID;
- (NSString *)displayName;
- (BOOL)isMe;

@end
