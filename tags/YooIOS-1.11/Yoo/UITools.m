//
//  UITools.m
//  Yoo
//
//  Created by Arnaud on 14/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "UITools.h"
#import "Contact.h"

@implementation UITools

+ (BOOL)isIOS8 {
    NSString *version = [[UIDevice currentDevice] systemVersion];
    return [version floatValue] >= 8.0;
}

+ (BOOL)isIOS7 {
    NSString *version = [[UIDevice currentDevice] systemVersion];
    return [version floatValue] >= 7.0;
}

+ (CGSize)getStringSize:(NSString *)s font:(UIFont *)font constraint:(CGSize)constraintSize {
    CGSize size;
    if ([NSString respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSDictionary *attributes = @{NSFontAttributeName: font};
        size = [s boundingRectWithSize:constraintSize
                                            options:NSStringDrawingUsesLineFragmentOrigin
                                         attributes:attributes
                                            context:nil].size;
    } else {
        size = [s sizeWithFont:font constrainedToSize:constraintSize];
    }
    return size;
}

+ (UIColor *)blueColor {
    return [UIColor colorWithRed:0.2 green:0.6 blue:0.9 alpha:1.0];
}

+ (void)setupTitleBar {
//    if ([UITools isIOS7]) {
//        [[UINavigationBar appearance] setBarTintColor:[UITools blueColor]];
//        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
//        
//        [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
//                                                               [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
//                                                               nil]];
//    }
}


+ (NSAttributedString *)attributedName:(Contact *)contact {
    NSDictionary *firstNameAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:18]};
    NSDictionary *lastNameAttributes = @{NSFontAttributeName : [UIFont boldSystemFontOfSize:18]};
    NSMutableAttributedString * name = [[NSMutableAttributedString alloc] init];
    if (contact.firstName.length > 0) {
        [name appendAttributedString:[[NSMutableAttributedString alloc] initWithString:contact.firstName attributes:contact.lastName.length > 0 ? firstNameAttributes : lastNameAttributes]];
    }
    if (contact.firstName.length > 0 && contact.lastName.length > 0) {
        [name appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:firstNameAttributes]];
    }
    if (contact.lastName.length > 0) {
        [name appendAttributedString:[[NSAttributedString alloc] initWithString:contact.lastName attributes:lastNameAttributes]];
    }
    return name;
}

@end
