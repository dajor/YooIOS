//
//  UITools.h
//  Yoo
//
//  Created by Arnaud on 14/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Contact.h"

@interface UITools : NSObject

+ (BOOL)isIOS7;
+ (CGSize)getStringSize:(NSString *)s font:(UIFont *)font constraint:(CGSize)constraintSize;
+ (void)setupTitleBar;
+ (NSAttributedString *)attributedName:(Contact *)contact;
+ (UIColor *)blueColor;

@end
