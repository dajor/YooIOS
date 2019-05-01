//
//  UserDAO.h
//  Yoo
//
//  Created by Arnaud on 27/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Criteria.h"
#import "YooUser.h"

@interface UserDAO : NSObject

+ (void)initTable;
+ (void)upsert:(YooUser *)yooMsg;
+ (NSArray *)list;
+ (YooUser *)find:(NSString *)name domain:(NSString *)domain;
+ (YooUser *)findByJid:(NSString *)jid;
+ (YooUser *)findByCriteria:(NSObject <Criteria> *)criteria;
+ (void)purge;
+ (void)setLastOnline:(NSString *)jid;
+ (void)remove:(NSString *)jid;

@end
