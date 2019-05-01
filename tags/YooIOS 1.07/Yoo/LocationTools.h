//
//  LocationTools.h
//  Yoo
//
//  Created by Arnaud on 31/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLGeocoder.h>
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import <CoreLocation/CLPlacemark.h>
#import "LocationListener.h"

@interface LocationTools : NSObject<CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, retain) NSObject <LocationListener> *listener;
@property (nonatomic, retain) NSString *gpsCountry;
@property (nonatomic, retain) NSString *carrierCountry;
@property (nonatomic, retain) NSString *langCountry;
@property (nonatomic, retain) CLLocation *location;

+ (LocationTools *)sharedInstance;
- (void)getCountryCode:(NSObject <LocationListener> *)pListener;
- (NSString *)fullPhone:(NSString *)phone;

@end
