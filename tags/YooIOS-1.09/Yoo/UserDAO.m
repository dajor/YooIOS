//
//  UserDAO.m
//  Yoo
//
//  Created by Arnaud on 27/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "UserDAO.h"
#import "Database.h"
#import "YooUser.h"
#import "EqualsCriteria.h"

@implementation UserDAO

+ (void)initTable {
    Database *database = [Database getInstance];
    NSMutableDictionary *columns = [[NSMutableDictionary alloc] initWithCapacity:1];
    [columns setObject:@"TEXT" forKey:@"jid"];
    [columns setObject:@"TEXT" forKey:@"alias"];
    [columns setObject:@"INTEGER" forKey:@"contactid"];
    [columns setObject:@"BLOB" forKey:@"picture"];
    [columns setObject:@"TEXT" forKey:@"callingCode"];
    [columns setObject:@"TEXT" forKey:@"lastonline"];
    [database check:@"yoouser" columns:columns];
    [database createIndex:@"yoouser" columns:@[@"jid"] unique:YES];
    [database createIndex:@"yoouser" columns:@[@"contactid"] unique:NO];
}

+ (void)purge {
    listCache = nil;
    [findCache removeAllObjects];
    [[Database getInstance] execSql:@"DELETE FROM yoouser" params:nil];
}

+ (void)upsert:(YooUser *)user {
    listCache = nil;
    [findCache removeObjectForKey:user.toJID];
    Database *database = [Database getInstance];
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    [item setObject:[user toJID] forKey:@"jid"];
    if (user.alias != nil) {
        [item setObject:user.alias forKey:@"alias"];
    }
    if (user.picture != nil) {
        [item setObject:user.picture forKey:@"picture"];
    }
    if (user.contactId != -1) {
        [item setObject:[NSNumber numberWithInteger:user.contactId] forKey:@"contactid"];
    }
    if (user.callingCode != -1){
        [item setObject:[NSString stringWithFormat:@"%d", user.callingCode] forKey:@"callingCode"];
    }
    // check if we don't have already this user
    NSObject <Criteria> *jidCrit = [[EqualsCriteria alloc] initWithField:@"jid" value:[user toJID]];
    NSArray *existing = [database select:@"yoouser" fields:@[@"jid"] criteria:jidCrit limit:1 order:nil];
    if (existing.count > 0) {
        [database update:@"yoouser" item:item criteria:jidCrit];
    } else {
        [database insert:@"yoouser" item:item];
    }
}

+ (YooUser *)findByCriteria:(NSObject <Criteria> *)criteria {
    Database *database = [Database getInstance];
    NSArray *existing = [database select:@"yoouser" fields:@[@"jid", @"alias", @"callingCode", @"contactid", @"picture", @"lastonline"] criteria:criteria limit:1 order:nil];
    if (existing.count > 0) {
        NSDictionary *row = [existing objectAtIndex:0];
        return [UserDAO mapRow:row];
    }
    return nil;
}


static NSMutableDictionary *findCache = nil;

+ (YooUser *)findByJid:(NSString *)jid {
    if (findCache == nil) {
        findCache = [NSMutableDictionary dictionary];
    }
    YooUser *yooUser = [findCache objectForKey:jid];
    if (yooUser == nil) {
        NSObject <Criteria> *jidCrit = [[EqualsCriteria alloc] initWithField:@"jid" value:jid];
        yooUser = [self findByCriteria:jidCrit];
        if (yooUser != nil) {
            [findCache setObject:yooUser forKey:jid];
        }
    }
    return yooUser;
}

+ (YooUser *)find:(NSString *)name domain:(NSString *)domain {
    NSString *jid = [NSString stringWithFormat:@"%@@%@", name, domain];
    return [self findByJid:jid];
}

+ (YooUser *)mapRow:(NSDictionary *)row {
    YooUser *user = [[YooUser alloc] initWithJID:[row objectForKey:@"jid"]];
    user.alias = [row objectForKey:@"alias"];
    user.contactId = [[row objectForKey:@"contactid"] integerValue];
    user.picture = [row objectForKey:@"picture"];
    user.callingCode = [[row objectForKey:@"callingCode"] intValue];
    if ([row objectForKey:@"lastonline"] != nil) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss:SSS"];
        user.lastonline = [df dateFromString:[row objectForKey:@"lastonline"]];
    }
    return user;
}

static NSArray *listCache = nil;

+ (NSArray *)list {
    if (listCache != nil) return listCache;
    NSMutableArray *users = [NSMutableArray array];
    Database *database = [Database getInstance];
    NSArray *rows = [database select:@"yoouser" fields:@[@"jid", @"alias", @"contactid", @"callingCode", @"picture", @"lastonline"] criteria:nil limit:0 order:nil];
    for (NSDictionary *row in rows) {
        [users addObject:[UserDAO mapRow:row]];
    }
    listCache = [users sortedArrayUsingSelector:@selector(compare:)];
    return listCache;
}

+ (void)setLastOnline:(NSString *)jid {
    // clear caches
    listCache = nil;
    [findCache removeObjectForKey:jid];
    
    Database *database = [Database getInstance];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss:SSS"];
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    [item setObject:[df stringFromDate:[NSDate date]] forKey:@"lastonline"];
    NSObject <Criteria> *jidCrit = [[EqualsCriteria alloc] initWithField:@"jid" value:jid];
    [database update:@"yoouser" item:item criteria:jidCrit];
    
}


@end
