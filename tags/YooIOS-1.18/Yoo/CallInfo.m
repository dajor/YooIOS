//
//  CallInfo.m
//  Yoo
//
//  Created by Arnaud on 27/02/2015.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import "CallInfo.h"

@implementation CallInfo

- (id)initWithStep:(PhoneCallStep)pStep number:(NSString *)pConfNumber {
    self = [super init];
    self.step = pStep;
    self.confNumber = pConfNumber;
    return self;
}

@end
