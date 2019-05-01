//
//  LocationListListener.h
//  Yoo
//
//  Created by Arnaud on 07/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKMapItem.h>

@protocol LocationListListener <NSObject>

- (void)didSelect:(MKMapItem *)item;

@end
