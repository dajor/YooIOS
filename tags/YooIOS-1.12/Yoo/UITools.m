//
//  UITools.m
//  Yoo
//
//  Created by Arnaud on 14/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "UITools.h"
#import "Contact.h"
#import <CoreText/CoreText.h>

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


//+ (CGSize)getStringSize:(NSString *)s font:(UIFont *)font constraint:(CGSize)constraintSize {
//    // Get text
//    CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
//    CFAttributedStringReplaceString (attrString, CFRangeMake(0, 0), (CFStringRef) s );
//    CFIndex stringLength = CFStringGetLength((CFStringRef) attrString);
//    
//    // Change font
//    CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef) font.fontName, font.pointSize, NULL);
//    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, stringLength), kCTFontAttributeName, ctFont);
//    
//    // Calc the size
//    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attrString);
//    CFRange fitRange;
//    CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(constraintSize.width, CGFLOAT_MAX), &fitRange);
//    
//    CFRelease(ctFont);
//    CFRelease(framesetter);
//    CFRelease(attrString);
//    
//    NSLog(@"%@ => %f", s, frameSize.width);
//    
//    return frameSize;
//}



+ (UIColor *)greenColor {
    return [UIColor colorWithRed:0.59 green:0.77 blue:0.27 alpha:1];
}




+ (NSAttributedString *)attributedName:(Contact *)contact {
    NSDictionary *firstNameAttributes = @{NSFontAttributeName : [UIFont fontWithName:@"Avenir" size:[UIFont buttonFontSize]]};
    NSDictionary *lastNameAttributes = @{NSFontAttributeName : [UIFont fontWithName:@"Avenir-Heavy" size:[UIFont buttonFontSize]]};
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
