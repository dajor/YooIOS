//
//  NotEqualsCriteria.m
//  Yoo
//
//  Created by Arnaud on 27/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "NotEqualsCriteria.h"

@implementation NotEqualsCriteria

- (id)initWithField:(NSString *)pField value:(NSString *)pValue {
    self = [super init];
    self.field = pField;
    self.value = pValue;
    return self;
}


- (NSString *)toSql {
    return [NSString stringWithFormat:@"(%@ != ? OR %@ IS NULL)", self.field, self.field];
}

- (NSArray *)getParams {
    return [NSArray arrayWithObject:self.value];
}

@end
