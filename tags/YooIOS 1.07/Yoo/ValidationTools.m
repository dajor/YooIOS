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
    if (tmp.length < 3) {
        return NSLocalizedString(@"NICKNAME_LENGTH", nil);
    }
    return nil;
}

@end
