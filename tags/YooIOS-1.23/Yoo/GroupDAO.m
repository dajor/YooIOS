//
//  GroupDAO.m
//  Yoo
//
//  Created by Arnaud on 05/03/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "GroupDAO.h"
#import "ChatDAO.h"
#import "Database.h"
#import "YooGroup.h"
#import "EqualsCriteria.h"
#import "ConjCriteria.h"
#import "ChatTools.h"

@implementation GroupDAO


+ (void)initTable {
    Database *database = [Database getInstance];
    NSMutableDictionary *columns = [[NSMutableDictionary alloc] initWithCapacity:1];
    [columns setObject:@"TEXT" forKey:@"jid"];
    [columns setObject:@"TEXT" forKey:@"alias"];
    [columns setObject:@"TEXT" forKey:@"date"];
    [database check:@"yoogroup" columns:columns];
    [database createIndex:@"yoogroup" columns:@[@"jid"] unique:YES];
    
    NSMutableDictionary *columns2 = [[NSMutableDictionary alloc] initWithCapacity:1];
    [columns2 setObject:@"TEXT" forKey:@"groupjid"];
    [columns2 setObject:@"TEXT" forKey:@"userjid"];
    [database check:@"groupmember" columns:columns2];
    [database createIndex:@"groupmember" columns:@[@"groupjid", @"userjid"] unique:YES];
}

+ (void)purge {
    if (cache != nil) [cache removeAllObjects];
    [[Database getInstance] execSql:@"DELETE FROM yoogroup" params:nil];
}

+ (void)upsert:(YooGroup *)group {
    if (cache != nil) {
        [cache removeObjectForKey:[group toJID]];
    }
    Database *database = [Database getInstance];
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    [item setObject:[group toJID] forKey:@"jid"];
    [item setObject:group.alias forKey:@"alias"];
    if (group.date != nil) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss:SSS"];
        [item setObject:[df stringFromDate:[NSDate date]] forKey:@"date"];
    }
    // check if we don't have already this group
    NSObject <Criteria> *jidCrit = [[EqualsCriteria alloc] initWithField:@"jid" value:[group toJID]];
    NSArray *existing = [database select:@"yoogroup" fields:@[@"jid"] criteria:jidCrit limit:1 order:nil];
    if (existing.count > 0) {
        [database update:@"yoogroup" item:item criteria:jidCrit];
    } else {
        [database insert:@"yoogroup" item:item];
    }
}

+ (void)remove:(NSString *)groupJid {
    if (cache != nil) {
        [cache removeObjectForKey:groupJid];
    }
    Database *database = [Database getInstance];
    NSObject <Criteria> *jidCrit = [[EqualsCriteria alloc] initWithField:@"jid" value:groupJid];
    [database remove:@"yoogroup" criteria:jidCrit];

    NSObject <Criteria> *groupCrit = [[EqualsCriteria alloc] initWithField:@"groupjid" value:groupJid];
    [database remove:@"groupmember" criteria:groupCrit];
    

    [ChatDAO markAsRead:groupJid];

}

+ (YooGroup *)findByCriteria:(NSObject <Criteria> *)criteria {
    Database *database = [Database getInstance];
    NSArray *existing = [database select:@"yoogroup" fields:@[@"jid", @"alias"] criteria:criteria limit:1 order:nil];
    if (existing.count > 0) {
        NSDictionary *row = [existing objectAtIndex:0];
        return [GroupDAO mapRow:row];
    }
    return nil;
}


static NSMutableDictionary *cache = nil;

+ (YooGroup *)find:(NSString *)name {
    NSString *jid = [NSString stringWithFormat:@"%@@%@", name, CONFERENCE_DOMAIN];
    if (cache == nil) {
        cache = [NSMutableDictionary dictionary];
    }
    YooGroup *group = [cache objectForKey:jid];
    if (group == nil) {
        NSObject <Criteria> *jidCrit = [[EqualsCriteria alloc] initWithField:@"jid" value:jid];
        group = [self findByCriteria:jidCrit];
        if (group != nil) {
            [cache setObject:group forKey:jid];
        }
    }
    return group;
}

+ (YooGroup *)mapRow:(NSDictionary *)row {
    NSArray *parts = [[row objectForKey:@"jid"] componentsSeparatedByString:@"@"];
    NSString *name = [parts objectAtIndex:0];
    NSString *alias = [row objectForKey:@"alias"];
    YooGroup *group = [[YooGroup alloc] initWithName:name alias:alias];
    if ([row objectForKey:@"date"] != nil) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss:SSS"];
        group.date = [df dateFromString:[row objectForKey:@"date"]];
    }
    return group;
}

+ (NSArray *)list {
    NSMutableArray *groups = [NSMutableArray array];
    Database *database = [Database getInstance];
    NSArray *rows = [database select:@"yoogroup" fields:@[@"jid", @"alias"] criteria:nil limit:0 order:nil];
    for (NSDictionary *row in rows) {
        [groups addObject:[GroupDAO mapRow:row]];
    }
    return [groups sortedArrayUsingSelector:@selector(compare:)];
}

+ (void)addMember:(NSString *)userJid toGroup:(NSString *)groupJid {
    Database *database = [Database getInstance];
    NSObject <Criteria> *groupCrit = [[EqualsCriteria alloc] initWithField:@"groupjid" value:groupJid];
    NSObject <Criteria> *userCrit = [[EqualsCriteria alloc] initWithField:@"userjid" value:userJid];
    ConjCriteria *andCrit = [[ConjCriteria alloc] initWithConjuction:conjAND];
    [andCrit.criterias addObject:groupCrit];
    [andCrit.criterias addObject:userCrit];
    NSArray *existing = [database select:@"groupmember" fields:@[@"groupjid"] criteria:andCrit limit:1 order:nil];
    if (existing.count == 0) {
        NSMutableDictionary *item = [NSMutableDictionary dictionary];
        [item setObject:groupJid forKey:@"groupjid"];
        [item setObject:userJid forKey:@"userjid"];
        [database insert:@"groupmember" item:item];
    }
}

+ (void)removeMember:(NSString *)userJid fromGroup:(NSString *)groupJid {
    Database *database = [Database getInstance];
    NSObject <Criteria> *groupCrit = [[EqualsCriteria alloc] initWithField:@"groupjid" value:groupJid];
    NSObject <Criteria> *userCrit = [[EqualsCriteria alloc] initWithField:@"userjid" value:userJid];
    ConjCriteria *andCrit = [[ConjCriteria alloc] initWithConjuction:conjAND];
    [andCrit.criterias addObject:groupCrit];
    [andCrit.criterias addObject:userCrit];
    [database remove:@"groupmember" criteria:andCrit];
}

+ (NSArray *)listMembers:(NSString *)groupJid {
    Database *database = [Database getInstance];
    NSObject <Criteria> *groupCrit = [[EqualsCriteria alloc] initWithField:@"groupjid" value:groupJid];
    NSMutableArray *members = [NSMutableArray array];
    NSArray *rows = [database select:@"groupmember" fields:@[@"userjid"] criteria:groupCrit limit:0 order:nil];
    for (NSDictionary *row in rows) {
        [members addObject:[row objectForKey:@"userjid"]];
    }
    return members;
}

@end
