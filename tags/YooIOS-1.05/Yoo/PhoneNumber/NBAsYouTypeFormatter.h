//
//  NBAsYouTypeFormatter.h
//  libPhoneNumber
//
//  Created by ishtar on 13. 2. 25..
//  Copyright (c) 2013년 NHN. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NBAsYouTypeFormatter : NSObject

- (id)initWithRegionCode:(NSString*)regionCode;
- (id)initWithRegionCodeForTest:(NSString*)regionCode;
- (id)initWithRegionCode:(NSString*)regionCode bundle:(NSBundle *)bundle;
- (id)initWithRegionCodeForTest:(NSString*)regionCode bundle:(NSBundle *)bundle;

- (NSString*)inputDigit:(NSString*)nextChar;
- (NSString*)inputDigitAndRememberPosition:(NSString*)nextChar;

- (NSString*)removeLastDigit;
- (NSString*)removeLastDigitAndRememberPosition;

- (int)getRememberedPosition;
- (void)clear;

@end