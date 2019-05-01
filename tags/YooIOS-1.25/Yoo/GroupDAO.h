//
//  GroupDAO.h
//  Yoo
//
//  Created by Arnaud on 05/03/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>


@class YooGroup;
@class YooUser;

@interface GroupDAO : NSObject


+ (void)initTable;
+ (void)upsert:(YooGroup *)yooGroup;
+ (YooGroup *)find:(NSString *)name;
+ (void)purge;
+ (NSArray *)list;
+ (void)remove:(NSString *)groupJid;
+ (void)addMember:(NSString *)userJid toGroup:(NSString *)groupJid;
+ (void)removeMember:(NSString *)userJid fromGroup:(NSString *)groupJid;
+ (NSArray *)listMembers:(NSString *)groupJid;

@end
