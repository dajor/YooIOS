//
//  YooMessage.m
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "YooMessage.h"
#import "ContactManager.h"
#import "UserDAO.h"

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

- (NSString *)toDisplay {
    if (self.type == ymtCallRequest) {
        YooUser *user = [UserDAO findByJid:self.to.toJID];
        if ([self.to isMe]) {
            return [NSString stringWithFormat:NSLocalizedString(@"CALL_FROM", nil), user.alias];
        } else {
            return [NSString stringWithFormat:NSLocalizedString(@"CALLING", nil), user.alias];
            
        }
    } else if (self.type == ymtContact) {
        Contact *contact = [[ContactManager sharedInstance] find:[self.shared integerValue]];
        return [NSString stringWithFormat:[self.from isMe] ? NSLocalizedString(@"SHARED_CONTACT", nil) : NSLocalizedString(@"RECEIVED_CONTACT", nil), contact.fullName];
    } else {
        return self.message;
    }
}

@end
