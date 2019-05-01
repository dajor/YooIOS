//
//  PicklistListener.h
//  Yoo
//
//  Created by Arnaud on 02/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PicklistListener <NSObject>

- (void)didSelect:(NSArray *)values tag:(NSInteger)tag;

@end
