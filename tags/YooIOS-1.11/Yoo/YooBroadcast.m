//
//  YooBroadcast.m
//  Yoo
//
//  Created by Arnaud on 10/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "YooBroadcast.h"

@implementation YooBroadcast


- (id)initWithNames:(NSArray *)pNames {
    self = [super init];
    self.names = pNames;
    return self;
}

- (NSString *)toJID {
    return BROADCAST_CODE;
}
- (BOOL)isMe {
    return NO;
}

@end
