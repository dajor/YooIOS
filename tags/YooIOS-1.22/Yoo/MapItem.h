//
//  MapItem.h
//  Yoo
//
//  Created by Arnaud on 03/06/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKMapItem.h>

@interface MapItem : NSObject

@property (nonatomic, retain) MKMapItem *position;
@property (nonatomic, retain) NSString *category;

@end
