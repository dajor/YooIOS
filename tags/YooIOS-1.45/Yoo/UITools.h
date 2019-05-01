//
//  UITools.h
//  Yoo
//
//  Created by Arnaud on 14/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"

@class YooUser;
@interface UITools : NSObject

+ (BOOL)isIOS8;
+ (BOOL)isIOS7;
+ (CGSize)getStringSize:(NSString *)s font:(UIFont *)font constraint:(CGSize)constraintSize;
+ (NSAttributedString *)attributedName:(Contact *)contact;
+ (UIColor *)greenColor;
+ (UIColor *)menuBackgroundColor ;
+ (UIColor *)menuSeparatorColor ;
+ (NSString *)lastOnlineDisplay:(YooUser *)user;
+ (void)forceAudioComeFromSpeaker;
@end
