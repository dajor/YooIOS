//
//  XMLTools.h
//  Yoo
//
//  Created by Arnaud on 14/01/2015.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMLTools : NSObject

+ (NSString *)escapeEmoji:(NSString *)s;
+ (NSString *)unescapeEmoji:(NSString *)s;

@end
