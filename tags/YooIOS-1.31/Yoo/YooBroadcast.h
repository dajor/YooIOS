//
//  YooBroadcast.h
//  Yoo
//
//  Created by Arnaud on 10/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YooRecipient.h"

#define BROADCAST_CODE @"broadcast"

@interface YooBroadcast : NSObject<YooRecipient>

@property (nonatomic, retain) NSArray *names;

- (id)initWithNames:(NSArray *)pNames;

@end
