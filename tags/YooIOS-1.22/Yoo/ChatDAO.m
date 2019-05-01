//
//  ChatDAO.m
//  Yoo
//
//  Created by Arnaud on 24/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "ChatDAO.h"
#import "Database.h"
#import "YooMessage.h"
#import "ConjCriteria.h"
#import "EqualsCriteria.h"
#import "NotEqualsCriteria.h"
#import "ChatTools.h"
#import "ContactManager.h"
#import "GroupDAO.h"

@implementation ChatDAO

+ (void)initTable {
    Database *database = [Database getInstance];
    NSMutableDictionary *columns = [[NSMutableDictionary alloc] initWithCapacity:1];
    [columns setObject:@"INTEGER PRIMARY KEY" forKey:@"yooid"];
    [columns setObject:@"TEXT" forKey:@"sender"];
    [columns setObject:@"TEXT" forKey:@"recipient"];
    [columns setObject:@"INTEGER" forKey:@"shared"];
    [columns setObject:@"TEXT" forKey:@"message"];
    [columns setObject:@"TEXT" forKey:@"id"];
    [columns setObject:@"TEXT" forKey:@"date"];
    [columns setObject:@"TEXT" forKey:@"read"];
    [columns setObject:@"TEXT" forKey:@"sent"];
    [columns setObject:@"TEXT" forKey:@"ack"];
    [columns setObject:@"TEXT" forKey:@"receipt"];
    [columns setObject:@"INTEGER" forKey:@"type"];
    [columns setObject:@"TEXT" forKey:@"location"];
    [columns setObject:@"TEXT" forKey:@"groupmember"];
    [columns setObject:@"BLOB" forKey:@"sound"];
    [columns setObject:@"TEXT" forKey:@"conferenceNumber"];
    [columns setObject:@"INTEGER" forKey:@"callstatus"];
    [columns setObject:@"TEXT" forKey:@"callReqId"];
    [database check:@"chat" columns:columns];
    [database createIndex:@"chat" columns:@[@"id"] unique:NO];
    [database createIndex:@"chat" columns:@[@"read"] unique:NO];
    [database createIndex:@"chat" columns:@[@"date"] unique:NO];
    [database createIndex:@"chat" columns:@[@"sender"] unique:NO];
    [database createIndex:@"chat" columns:@[@"recipient"] unique:NO];
    msgCache = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *columns2 = [[NSMutableDictionary alloc] initWithCapacity:1];
    [columns2 setObject:@"TEXT" forKey:@"yooid"];
    [columns2 setObject:@"TEXT" forKey:@"picid"];
    [columns2 setObject:@"BLOB" forKey:@"data"];
    [database check:@"picture" columns:columns2];
    [database createIndex:@"picture" columns:@[@"yooid", @"picid"] unique:YES];
}

+ (void)purge {
    [[Database getInstance] execSql:@"DELETE FROM chat" params:nil];
    [[Database getInstance] execSql:@"DELETE FROM picture" params:nil];
}


+ (YooMessage *)findById:(NSString *)idMsg {
    Database *database = [Database getInstance];
    NSObject<Criteria> *idCrit = [[EqualsCriteria alloc] initWithField:@"id" value:idMsg];
    NSArray *rows = [database select:@"chat" fields:[ChatDAO allFields] criteria:idCrit limit:0 order:nil];
    if (rows.count > 0) {
        NSDictionary *row = [rows objectAtIndex:0];
        return [ChatDAO mapRow:row];
    }
    return nil;
}

+ (YooMessage *)acknowledge:(NSString *)idMsg {
    YooMessage *origMsg = [self findById:idMsg];
    if (origMsg != nil) {
        Database *database = [Database getInstance];
        NSMutableDictionary *item = [NSMutableDictionary dictionary];
        [item setObject:@"1" forKey:@"ack"];
        [database update:@"chat" item:item criteria:[[EqualsCriteria alloc] initWithField:@"id" value:idMsg]];
    }
    return origMsg;
}

+ (void)updateCall:(NSString *)jid ident:(NSString *)ident status:(CallStatus)status {
    [msgCache removeObjectForKey:jid];
    Database *database = [Database getInstance];
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    [item setObject:[NSString stringWithFormat:@"%ld", status] forKey:@"callstatus"];
    [database update:@"chat" item:item criteria:[[EqualsCriteria alloc] initWithField:@"id" value:ident]];
}

+ (void)markAsSent:(NSString *)jid ident:(NSString *)ident {
    [msgCache removeObjectForKey:jid];
    Database *database = [Database getInstance];
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    [item setObject:@"1" forKey:@"sent"];
    [database update:@"chat" item:item criteria:[[EqualsCriteria alloc] initWithField:@"id" value:ident]];
}

+ (void)markAsRead:(NSString *)jid {
    [msgCache removeObjectForKey:jid];
    Database *database = [Database getInstance];
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    [item setObject:@"1" forKey:@"read"];
    [item setObject:@"0" forKey:@"receipt"];
    [database update:@"chat" item:item criteria:[[EqualsCriteria alloc] initWithField:@"sender" value:jid]];
    [database update:@"chat" item:item criteria:[[EqualsCriteria alloc] initWithField:@"recipient" value:jid]];
}

+ (NSArray *)unreadList:(NSObject<YooRecipient> *)recipient {
    NSMutableArray *unread = [NSMutableArray array];
    Database *database = [Database getInstance];
    NSObject <Criteria> *unreadCrit = [[NotEqualsCriteria alloc] initWithField:@"read" value:@"1"];
    NSObject <Criteria> *senderCrit = [[EqualsCriteria alloc] initWithField:@"sender" value:recipient.toJID];
    ConjCriteria *andCrit = [[ConjCriteria alloc] initWithConjuction:conjAND];
    [andCrit.criterias addObject:unreadCrit];
    [andCrit.criterias addObject:senderCrit];
    NSArray *received = [database select:@"chat" fields:[ChatDAO allFields] criteria:andCrit limit:0 order:nil];
    for (NSDictionary *row in received) {
        YooMessage *message = [ChatDAO mapRow:row];
        [unread addObject:message];
    }
    return unread;
}

+ (void)deletePictures:(NSObject <Criteria> *)crit {
    Database *database = [Database getInstance];
    NSArray *rows = [database select:@"chat" fields:@[@"yooid"] criteria:crit limit:0 order:nil];
    for (NSDictionary *row in rows) {
        NSString *yooid = [row objectForKey:@"yooid"];
        [database remove:@"picture" criteria:[[EqualsCriteria alloc] initWithField:@"yooid" value:yooid]];
    }
}

+ (void)deleteForRecipient:(NSString *)jid {
    [msgCache removeObjectForKey:jid];
    Database *database = [Database getInstance];
    NSObject <Criteria> *senderCrit = [[EqualsCriteria alloc] initWithField:@"sender" value:jid];
    [ChatDAO deletePictures:senderCrit];
    [database remove:@"chat" criteria:senderCrit];
    NSObject <Criteria> *recipCrit = [[EqualsCriteria alloc] initWithField:@"recipient" value:jid];
    [ChatDAO deletePictures:recipCrit];
    [database remove:@"chat" criteria:recipCrit];
}

+ (NSInteger)unreadCountForSender:(NSObject<YooRecipient> *)recipient {
    Database *database = [Database getInstance];
    NSArray *result = [database selectSql:@"SELECT COUNT(*) total FROM chat WHERE read != '1' AND sender = ?" params:@[recipient.toJID] fields:@[@"total"]];
    if (result.count > 0) {
        return [[[result objectAtIndex:0] objectForKey:@"total"] integerValue];
    }
    return 0;
}

+ (NSInteger)unreadCount {
    Database *database = [Database getInstance];
    NSArray *result = [database selectSql:@"SELECT COUNT(*) total FROM chat WHERE read != '1'" params:nil fields:@[@"total"]];
    if (result.count > 0) {
        return [[[result objectAtIndex:0] objectForKey:@"total"] integerValue];
    }
    return 0;
}

+ (void)insert:(YooMessage *)yooMsg {
    [msgCache removeObjectForKey:yooMsg.from.toJID];
    [msgCache removeObjectForKey:yooMsg.to.toJID];
    Database *database = [Database getInstance];
    // check if we don't have already this message
    if (yooMsg.ident.length > 0) {
        NSArray *existing = [database select:@"chat" fields:@[@"id"] criteria:[[EqualsCriteria alloc] initWithField:@"id" value:yooMsg.ident] limit:1 order:nil];
        if (existing.count > 0) {
            return;
        }
    }
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    if (yooMsg.ident.length > 0) {
        [item setObject:yooMsg.ident forKey:@"id"];
    }
    if (yooMsg.message != nil) {
        [item setObject:yooMsg.message forKey:@"message"];
    }
    [item setObject:[NSNumber numberWithInt:yooMsg.type] forKey:@"type"];
    if (yooMsg.type == ymtLocation) {
        [item setObject:[NSString stringWithFormat:@"%f/%f", yooMsg.location.latitude, yooMsg.location.longitude] forKey:@"location"];
    }
    [item setObject:[yooMsg.from toJID] forKey:@"sender"];
    if ([yooMsg.from isKindOfClass:[YooGroup class]]) {
        NSString *member = ((YooGroup *)yooMsg.from).member;
        [item setObject:member forKey:@"groupmember"];
    }
    [item setObject:[yooMsg.to toJID] forKey:@"recipient"];
    if (yooMsg.shared != nil) {
        [item setObject:yooMsg.shared forKey:@"shared"];
    }
    [item setObject:yooMsg.read ? @"1" : @"0" forKey:@"read"];
    [item setObject:yooMsg.sent ? @"1" : @"0" forKey:@"sent"];
    [item setObject:yooMsg.receipt ? @"1" : @"0" forKey:@"receipt"];
    if ([yooMsg.sound length] > 0) {
        [item setObject:yooMsg.sound forKey:@"sound"];
    }

    if (yooMsg.conferenceNumber != nil) {
        [item setObject:yooMsg.conferenceNumber forKey:@"conferencenumber"];
    }
    [item setObject:[NSNumber numberWithInt:yooMsg.callStatus] forKey:@"callstatus"];
    if (yooMsg.callReqId != nil) {
        [item setObject:yooMsg.callReqId forKey:@"callReqId"];
    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss:SSS"];
    if (yooMsg.date == nil) {
        [item setObject:[df stringFromDate:[NSDate date]] forKey:@"date"];
    } else {
        [item setObject:[df stringFromDate:yooMsg.date] forKey:@"date"];
    }
    
    [database insert:@"chat" item:item];
    
    yooMsg.yooId = [self getLastYooId];
    
    if (yooMsg.pictures.count > 0) {
        NSInteger i = 1;
        for (NSData *picData in yooMsg.pictures) {
            NSMutableDictionary *item2 = [NSMutableDictionary dictionary];
            [item2 setObject:yooMsg.yooId forKey:@"yooid"];
            [item2 setObject:[NSString stringWithFormat:@"%ld", (long)i] forKey:@"picid"];
            [item2 setObject:picData forKey:@"data"];
            [database insert:@"picture" item:item2];
            i++;
        }
        
    }
}

static NSMutableDictionary *msgCache = nil;

+ (NSArray *)allFields {
    return @[@"yooid", @"id", @"type", @"message", @"sender", @"recipient", @"read",  @"location", @"ack", @"sent", @"receipt", @"date", @"shared", @"groupmember", @"sound", @"conferenceNumber", @"callstatus", @"callreqid"];
}

+ (YooMessage *)mapRow:(NSDictionary *)row {
    YooMessage *yooMsg = [[YooMessage alloc] init];
    yooMsg.type = [[row objectForKey:@"type"] integerValue];
    yooMsg.yooId = [row objectForKey:@"yooid"];
    yooMsg.ident = [row objectForKey:@"id"];
    yooMsg.ack = [[row objectForKey:@"ack"] isEqualToString:@"1"];
    yooMsg.sent = [[row objectForKey:@"sent"] isEqualToString:@"1"];
    yooMsg.message = [row objectForKey:@"message"];
    if ([[row objectForKey:@"sender"] hasSuffix:CONFERENCE_DOMAIN]) {
        NSArray *parts = [[row objectForKey:@"sender"] componentsSeparatedByString:@"@"];
        NSString *groupCode = [parts objectAtIndex:0];
        YooGroup *group = [GroupDAO find:groupCode];
        group.member = [row objectForKey:@"groupmember"];
        yooMsg.from = group;
    } else {
        yooMsg.from = [[YooUser alloc] initWithJID:[row objectForKey:@"sender"]];
    }
    if ([[row objectForKey:@"recipient"] hasSuffix:CONFERENCE_DOMAIN]) {
        NSArray *parts = [[row objectForKey:@"recipient"] componentsSeparatedByString:@"@"];
        NSString *groupCode = [parts objectAtIndex:0];
        YooGroup *group = [GroupDAO find:groupCode];
        yooMsg.to = group;
    } else {
        yooMsg.to = [[YooUser alloc] initWithJID:[row objectForKey:@"recipient"]];
    }
    if ([[row objectForKey:@"sound"] length] > 0) {
        yooMsg.sound = [row objectForKey:@"sound"];
    }
    yooMsg.shared = [row objectForKey:@"shared"] != nil ? [NSNumber numberWithInteger:[[row objectForKey:@"shared"] integerValue]] : nil;
    yooMsg.read = [[row objectForKey:@"read"] isEqualToString:@"1"];
    yooMsg.receipt = [[row objectForKey:@"receipt"] isEqualToString:@"1"];
    yooMsg.conferenceNumber = [row objectForKey:@"conferencenumber"];
    yooMsg.callReqId = [row objectForKey:@"callreqid"];
    yooMsg.callStatus = [[row objectForKey:@"callstatus"] integerValue];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss:SSS"];
    yooMsg.date = [df dateFromString:[row objectForKey:@"date"]];
    if ([[row objectForKey:@"location"] length] > 0) {
        NSArray *parts = [[row objectForKey:@"location"] componentsSeparatedByString:@"/"];
        yooMsg.location = CLLocationCoordinate2DMake([[parts objectAtIndex:0] doubleValue], [[parts objectAtIndex:1] doubleValue]);
    }

    
    return yooMsg;
}

+ (NSInteger)countReceived:(YooUser *)user {
    Database *database = [Database getInstance];
    NSArray *rows = [database selectSql:@"SELECT COUNT(*) total FROM chat WHERE recipient = ?" params:@[user.toJID] fields:@[@"total"]];
    if (rows.count == 1) {
        return [[[rows objectAtIndex:0] objectForKey:@"total"] integerValue];
    }
    return 0;
}

+ (NSInteger)countSent:(YooUser *)user {
    Database *database = [Database getInstance];
    NSArray *rows = [database selectSql:@"SELECT COUNT(*) total FROM chat WHERE sender = ?" params:@[user.toJID] fields:@[@"total"]];
    if (rows.count == 1) {
        return [[[rows objectAtIndex:0] objectForKey:@"total"] integerValue];
    }
    return 0;
}

+ (NSArray *)list:(NSObject<YooRecipient> *)recipient withPictures:(BOOL)pict limit:(int)limit {
    if (pict == NO) {
        NSArray *existing = [msgCache objectForKey:recipient.toJID];
        if (existing != nil) {
            return existing;
        }
    }
    NSMutableArray *msgs = [NSMutableArray array];
    Database *database = [Database getInstance];
    ConjCriteria *orCrit = [[ConjCriteria alloc] initWithConjuction:conjOR];
    [orCrit.criterias addObject:[[EqualsCriteria alloc] initWithField:@"sender" value:recipient.toJID]];
    [orCrit.criterias addObject:[[EqualsCriteria alloc] initWithField:@"recipient" value:recipient.toJID]];
    NSArray *rows = [database select:@"chat" fields:[ChatDAO allFields] criteria:orCrit limit:limit order:@"date DESC"];
    for (NSDictionary *row in rows) {
        YooMessage *yooMsg = [ChatDAO mapRow:row];
        if (pict && yooMsg.type == ymtPicture) {
            NSObject<Criteria> *picCrit = [[EqualsCriteria alloc] initWithField:@"yooid" value:yooMsg.yooId];
            NSArray *rows2 = [database select:@"picture" fields:@[@"data"] criteria:picCrit limit:0 order:@"picid ASC"];
            if (rows2.count > 0) {
                NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:rows2.count];
                for (NSDictionary *row2 in rows2) {
                    [tmp addObject:[row2 objectForKey:@"data"]];
                }
                yooMsg.pictures = tmp;
            }
        }
        [msgs insertObject:yooMsg atIndex:0];
    }
    if (pict == NO) {
        [msgCache setObject:msgs forKey:recipient.toJID];
    }
    return msgs;
}

+ (NSString *)getLastYooId {
    NSArray *items = [[Database getInstance] selectSql:@"SELECT MAX(yooid) FROM chat" params:nil fields:[NSArray arrayWithObject:@"yooid"]];
    if ([items count] > 0) {
        NSDictionary *itemFields = [items objectAtIndex:0];
        return [itemFields objectForKey:@"yooid"];
    }
    return nil;
}

+(NSArray*) unsentList: (NSObject<YooRecipient> *)recipient
{
    NSMutableArray * unsentMessages = [[NSMutableArray alloc] init];
    NSArray *yooMessages = [[ChatTools sharedInstance] messagesForRecipient:recipient withPicture:YES limit:0];

    for(YooMessage *yooMsg in yooMessages)
    {
        NSObject<YooRecipient> *from = yooMsg.from;
        if (yooMsg.sent == NO && [recipient.toJID isEqualToString: from.toJID]) {
            [unsentMessages addObject:yooMsg];
            
        }
    }
    
    return unsentMessages;
}

@end
