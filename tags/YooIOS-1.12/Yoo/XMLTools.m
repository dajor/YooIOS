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
    NSData *data = [s dataUsingEncoding:NSNonLossyASCIIStringEncoding];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSString *)unescapeEmoji:(NSString *)s {
    NSData *data = [s dataUsingEncoding:NSUTF8StringEncoding];
    return [[NSString alloc] initWithData:data encoding:NSNonLossyASCIIStringEncoding];
}

@end
