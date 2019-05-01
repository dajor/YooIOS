//
//  RecordListener.h
//  Yoo
//
//  Created by Arnaud on 09/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RecordListener <NSObject>

- (void)didRecord:(NSData *)sound duration:(NSString *)duration;

@end
