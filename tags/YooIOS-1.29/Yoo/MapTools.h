//
//  MapTools.h
//  Yoo
//
//  Created by Arnaud on 07/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapSearchListener.h"

@interface MapTools : NSObject

+ (void)search:(NSString *)category listener:(NSObject <MapSearchListener> *)listener;

@end
