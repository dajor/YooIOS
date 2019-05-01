//
//  ContactDAO.m
//  Yoo
//
//  Created by Arnaud on 07/02/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "ContactDAO.h"
#import "Database.h"
#import "EqualsCriteria.h"

@implementation ContactDAO

+ (void)initTable {
    Database *database = [Database getInstance];
    NSMutableDictionary *columns = [[NSMutableDictionary alloc] initWithCapacity:1];
    [columns setObject:@"INTEGER PRIMARY KEY" forKey:@"contactid"];
    [columns setObject:@"TEXT" forKey:@"firstname"];
    [columns setObject:@"TEXT" forKey:@"lastname"];
    [columns setObject:@"TEXT" forKey:@"hasphone"];
    [database check:@"contact" columns:columns];
}

+ (void)purge {
    [findCache removeAllObjects];
    [[Database getInstance] execSql:@"DELETE FROM contact" params:nil];
}

+ (Contact *)mapRow:(NSDictionary *)row {
    Contact *contact = [[Contact alloc] init];
    contact.contactId = [[row objectForKey:@"contactid"] integerValue];
    contact.firstName = [row objectForKey:@"firstname"];
    contact.lastName = [row objectForKey:@"lastname"];
    contact.hasPhone = [[row objectForKey:@"hasphone"] isEqualToString:@"1"];
    return contact;
}

+ (NSArray *)list {
    NSMutableArray *contacts = [NSMutableArray array];
    Database *database = [Database getInstance];
    NSArray *rows = [database select:@"contact" fields:@[@"contactid", @"firstname", @"lastname", @"hasphone"] criteria:nil limit:0 order:nil];
    for (NSDictionary *row in rows) {
        [contacts addObject:[ContactDAO mapRow:row]];
    }

    return contacts;
}


static NSMutableDictionary *findCache = nil;


+ (Contact *)find:(NSInteger)contactId {
    if (findCache == nil) {
        findCache = [NSMutableDictionary dictionary];
    }
    Contact *contact = [findCache objectForKey:[NSNumber numberWithInteger:contactId]];
    if (contact == nil) {
        Database *database = [Database getInstance];
        NSObject <Criteria> *idCrit = [[EqualsCriteria alloc] initWithField:@"contactid" value:[NSString stringWithFormat:@"%ld", (long)contactId]];
        NSArray *rows = [database select:@"contact" fields:@[@"contactid", @"firstname", @"lastname", @"hasphone"] criteria:idCrit limit:1 order:nil];
        if (rows.count > 0) {
            NSDictionary *row = [rows objectAtIndex:0];
            contact = [ContactDAO mapRow:row];
            [findCache setObject:contact forKey:[NSNumber numberWithInteger:contactId]];
        }
    }
    return contact;
}

+ (void)upsert:(Contact *)contact {
    [findCache removeObjectForKey:[NSNumber numberWithInteger:contact.contactId]];
    Database *database = [Database getInstance];
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    [item setObject:[NSNumber numberWithInteger:contact.contactId] forKey:@"contactid"];
    if (contact.lastName != nil) {
        [item setObject:contact.lastName forKey:@"lastname"];
    }
    if (contact.firstName != nil) {
        [item setObject:contact.firstName forKey:@"firstname"];
    }
    if (contact.phones.count > 0) {
        [item setObject:@"1" forKey:@"hasphone"];
    } else {
        [item setObject:@"0" forKey:@"hasphone"];
    }
    
    // check if we don't have already this user
    NSObject <Criteria> *idCrit = [[EqualsCriteria alloc] initWithField:@"contactid" value:[NSString stringWithFormat:@"%ld",(long)contact.contactId]];
    NSArray *existing = [database select:@"contact" fields:@[@"contactid"] criteria:idCrit limit:1 order:nil];
    if (existing.count > 0) {
        [database update:@"contact" item:item criteria:idCrit];
    } else {
        [database insert:@"contact" item:item];
    }
}

+ (void)remove:(NSInteger)contactId {
    
    [findCache removeObjectForKey:[NSNumber numberWithInteger:contactId]];
    Database *database = [Database getInstance];
    NSObject <Criteria> *idCrit = [[EqualsCriteria alloc] initWithField:@"contactid" value:[NSString stringWithFormat:@"%ld", (long)contactId]];
    [database remove:@"contact" criteria:idCrit];
}

@end
