//
//  MapTools.m
//  Yoo
//
//  Created by Arnaud on 07/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "MapTools.h"
#import "LocationTools.h"
#import <MapKit/MKMapItem.h>
#import <MapKit/MKLocalSearch.h>
#import <MapKit/MKLocalSearchRequest.h>
#import <MapKit/MKLocalSearchResponse.h>
#import "MapSearchListener.h"

@implementation MapTools

+ (void)search:(NSString *)query listener:(NSObject <MapSearchListener> *)listener {
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    CLLocationCoordinate2D location = [LocationTools sharedInstance].location.coordinate;
    //CLLocationCoordinate2D location = CLLocationCoordinate2DMake(11.567898, 104.894430);
    request.naturalLanguageQuery = query;
    request.region = MKCoordinateRegionMakeWithDistance(location, 1000, 1000);
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error){
        if (error == nil) {
            [listener didFind:response.mapItems query:query];
        }
    }];
}

@end
