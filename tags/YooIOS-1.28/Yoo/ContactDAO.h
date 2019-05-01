//
//  ContactDAO.h
//  Yoo
//
//  Created by Arnaud on 07/02/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"

@interface ContactDAO : NSObject

+ (void)initTable;
+ (void)upsert:(Contact *)contact;
+ (void)remove:(NSInteger)contactId;
+ (void)purge;
+ (NSArray *)list;
+ (Contact *)find:(NSInteger)contactId;

@end
