//
//  Contact.h
//  Yoo
//
//  Created by Arnaud on 06/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Contact : NSObject

@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSString *company;
@property (nonatomic, retain) NSString *jobTitle;
@property (assign) NSInteger contactId;
@property (nonatomic, retain) NSMutableArray *emails;
@property (nonatomic, retain) NSMutableArray *phones;
@property (nonatomic, retain) NSMutableArray *messaging;
@property (nonatomic, retain) UIImage *image;
@property (assign) BOOL hasPhone;

- (NSString *)fullName;
- (NSComparisonResult)compare:(Contact *)other;

@end
