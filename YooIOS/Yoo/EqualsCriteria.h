//
//  EqualsCriteria.h
//  Yoo
//
//  Created by Arnaud on 01/05/13.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Criteria.h"

@interface EqualsCriteria : NSObject<Criteria> {
}

@property (nonatomic, retain) NSString *field;
@property (nonatomic, retain) NSString *value;

- (id)initWithField:(NSString *)pField value:(NSString *)pValue;

@end
