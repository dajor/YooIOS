//
//  NotEqualsCriteria.h
//  Yoo
//
//  Created by Arnaud on 27/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Criteria.h"

@interface NotEqualsCriteria : NSObject<Criteria>

@property (nonatomic, retain) NSString *field;
@property (nonatomic, retain) NSString *value;

- (id)initWithField:(NSString *)pField value:(NSString *)pValue;

@end
