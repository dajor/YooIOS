//
//  Contact.m
//  Yoo
//
//  Created by Arnaud on 06/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "Contact.h"

@implementation Contact

- (id)init {
    self = [super init];
    self.firstName = nil;
    self.lastName = nil;
    self.company = nil;
    self.jobTitle = nil;
    self.phones = [NSMutableArray array];
    self.emails = [NSMutableArray array];
    self.messaging = [NSMutableArray array];
    self.image = nil;
    return self;
}

- (NSString *)fullName {
    if (self.firstName == nil) return self.lastName;
    if (self.lastName == nil) return self.firstName;
    return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}


- (NSComparisonResult)compare:(Contact *)other {
    NSString *key = self.lastName == nil ? self.firstName : [NSString stringWithFormat:@"%@ %@", self.lastName, self.firstName];
    NSString *keyOther = other.lastName == nil ? other.firstName : [NSString stringWithFormat:@"%@ %@", other.lastName, other.firstName];
    return [key caseInsensitiveCompare:keyOther];
}

@end
