//
//  YooGroup.h
//  Yoo
//
//  Created by Arnaud on 05/03/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YooRecipient.h"

@interface YooGroup : NSObject<YooRecipient>

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *alias;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *member;

- (id)initWithName:(NSString *)pName alias:(NSString *)pAlias;
- (NSString *)toJID;

@end
