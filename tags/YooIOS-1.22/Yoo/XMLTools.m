//
//  XMLTools.m
//  Yoo
//
//  Created by Arnaud on 14/01/2015.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import "XMLTools.h"

@implementation XMLTools

+ (NSString *)escapeEmoji:(NSString *)s {
    return [s stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)unescapeEmoji:(NSString *)s {
    return [s stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
