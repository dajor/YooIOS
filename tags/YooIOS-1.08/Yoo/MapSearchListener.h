//
//  MapSearchListener.h
//  Yoo
//
//  Created by Arnaud on 07/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MapSearchListener <NSObject>

- (void)didFind:(NSArray *)items query:(NSString *)query;

@end
