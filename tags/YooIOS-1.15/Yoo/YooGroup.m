//
//  YooGroup.m
//  Yoo
//
//  Created by Arnaud on 05/03/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "YooGroup.h"
#import "ChatTools.h"

@implementation YooGroup

- (id)init {
    return [self initWithName:nil alias:nil];
}

- (id)initWithName:(NSString *)pName alias:(NSString *)pAlias {
    self = [super init];
    self.name = pName;
    self.alias = pAlias;
    self.date = nil;
    self.member = nil;
    return self;
}

- (NSString *)toJID {
    return [NSString stringWithFormat:@"%@@%@", self.name, CONFERENCE_DOMAIN];
}

- (int)compare:(YooGroup *)other {
    return [self.alias compare:other.alias];
}

- (BOOL)isMe {
    return NO;
}

@end
