//
//  ValidationTools.m
//  Yoo
//
//  Created by Arnaud on 06/02/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "ValidationTools.h"

@implementation ValidationTools


+ (NSString *)validateNickname:(NSString *)nickname {
    NSString *tmp = [nickname stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (tmp.length < 3 || tmp.length > 30) {
        return NSLocalizedString(@"NICKNAME_LENGTH", nil);
    }
    return nil;
}

+ (NSString *)validateGroupName:(NSString *)groupName {
    NSString *tmp = [groupName stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (tmp.length < 3 || tmp.length > 30) {
        return NSLocalizedString(@"GROUPNAME_LENGTH", nil);
    }
    return nil;
}

@end
