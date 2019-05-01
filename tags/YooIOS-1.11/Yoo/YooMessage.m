//
//  YooMessage.m
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "YooMessage.h"

@implementation YooMessage

- (id)init {
    self = [super init];
    self.type = ymtText;
    self.message = nil;
    self.read = NO;
    self.sent = NO;
    self.pictures = nil;
    self.from = nil;
    self.to = nil;
    self.thread = nil;
    self.ident = nil;
    self.yooId = nil;
    self.ack = NO;
    self.receipt = NO;
    self.date = nil;
    self.shared = nil;
    self.conferenceNumber = nil;
    return self;
}

@end
