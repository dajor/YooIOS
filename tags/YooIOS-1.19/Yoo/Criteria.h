//
//  Criteria.h
//  Yoo
//
//  Created by Arnaud on 24/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Criteria <NSObject>

- (NSArray *)getParams;
- (NSString *)toSql;

@end
