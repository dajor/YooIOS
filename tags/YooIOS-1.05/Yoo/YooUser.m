//
//  YooUser.m
//  Yoo
//
//  Created by Arnaud on 16/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "YooUser.h"
#import "ImageTools.h"

@implementation YooUser

- (id)initWithName:(NSString *)pName domain:(NSString *)pDomain {
    self = [super init];
    self.name = pName;
    self.domain = pDomain;
    self.alias = nil;
    self.picture = nil;
    self.contactId = -1;
    self.lastonline = nil;
    self.countryCode = -1;
    return self;
}


- (id)initWithJID:(NSString *)jid {
    NSArray *parts = [jid componentsSeparatedByString:@"@"];
    if (parts.count != 2) return nil;
    self = [super init];
    self.name = [parts objectAtIndex:0];
    self.domain = [parts objectAtIndex:1];
    self.alias = nil;
    self.picture = nil;
    self.contactId = -1;
    self.lastonline = nil;
    self.countryCode = -1;
    return self;
}

- (NSString *)displayName {
    if (self.alias != nil) return self.alias;
    return [self.name capitalizedString];
}

- (BOOL)isSame:(YooUser *)other {
    return [self.name isEqualToString:other.name] && [self.domain isEqualToString:other.domain];
}

- (NSString *)toJID {
    return [NSString stringWithFormat:@"%@@%@", self.name, self.domain];
}

- (int)compare:(YooUser *)other {
    return [self.displayName compare:other.displayName];
}

- (BOOL)isMe {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *login = [userDefaults stringForKey:@"login"];
    return [login isEqualToString:self.name];
}


@end
