//
//  UserDAO.h
//  Yoo
//
//  Created by Arnaud on 27/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YooUser;

@interface UserDAO : NSObject

+ (void)initTable;
+ (void)upsert:(YooUser *)yooMsg;
+ (NSArray *)list;
+ (YooUser *)find:(NSString *)name domain:(NSString *)domain;
+ (YooUser *)findByJid:(NSString *)jid;
+ (void)purge;
+ (void)setLastOnline:(NSString *)jid;

@end
