//
//  Activity.h
//  Yoo
//
//  Created by Arnaud on 01/04/2015.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Activity : NSObject

@property (nonatomic, retain) NSArray *sections;
@property (nonatomic, retain) NSDictionary *yooRecipients;
@property (nonatomic, retain) NSDictionary *contactMap;

- (NSArray *)flatten;

@end
