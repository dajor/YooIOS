//
//  EqualsCriteria.m
//  Yoo
//
//  Created by Arnaud on 01/05/13.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "EqualsCriteria.h"

@implementation EqualsCriteria


- (id)initWithField:(NSString *)pField value:(NSString *)pValue {
    self = [super init];
    self.field = pField;
    self.value = pValue;
    return self;
}


- (NSString *)toSql {
    return [NSString stringWithFormat:@"%@ = ?", self.field];
}

- (NSArray *)getParams {
    return [NSArray arrayWithObject:self.value];
}

@end
