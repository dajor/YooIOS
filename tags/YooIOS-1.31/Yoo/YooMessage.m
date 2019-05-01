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
#import "ContactDAO.h"
#import "Contact.h"
#import "LabelledValue.h"
#import "ChatTools.h"

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
    self.readByOther = NO;
    self.date = nil;
    self.shared = nil;
    self.callStatus = csNone;
    self.conferenceNumber = nil;
    self.callReqId = nil;
    return self;
}

- (NSString *)toDisplay {
    if (self.type == ymtCallRequest) {
        if ([self.to isKindOfClass:[YooGroup class]]) {
            YooGroup *group = (YooGroup *)self.to;
            return [NSString stringWithFormat:NSLocalizedString(@"CALLING", nil), group.alias];
        } else {
            YooUser *user = [UserDAO findByJid:self.to.toJID];
            if ([self.to isMe]) {
                YooUser *fromUser = [UserDAO findByJid:self.from.toJID];
                //For Group Call
                if(fromUser == nil && [self.from isKindOfClass:[YooGroup class]]){
                    fromUser = [UserDAO findByJid:[NSString stringWithFormat:@"%@@%@", [(YooGroup *)self.from member], YOO_DOMAIN]];
                }
                Contact *contact = [[ContactManager sharedInstance] find:fromUser.contactId];
                NSString *phone  = @"";
                if([contact.phones count] > 0){
                    LabelledValue *p = contact.phones[0];
                    phone = p.value;
                }

                return [NSString stringWithFormat:NSLocalizedString(@"CALL_FROM", nil), fromUser.alias,phone];
            } else {
                return [NSString stringWithFormat:NSLocalizedString(@"CALLING", nil), user.alias];
            }
        }
    } else if (self.type == ymtContact) {
        Contact *contact = [[ContactManager sharedInstance] find:[self.shared integerValue]];
        return [NSString stringWithFormat:[self.from isMe] ? NSLocalizedString(@"SHARED_CONTACT", nil) : NSLocalizedString(@"RECEIVED_CONTACT", nil), contact.fullName];
    } else {
        return self.message;
    }
}

@end
