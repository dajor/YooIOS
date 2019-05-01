//
//  LocationTools.m
//  Yoo
//
//  Created by Arnaud on 31/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "LocationTools.h"
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "NBPhoneNumberUtil.h"

@implementation LocationTools

static LocationTools *instance = nil;

+ (LocationTools *)sharedInstance {
    if (instance == nil) {
        instance = [[LocationTools alloc] init];
    }
    return instance;
}

- (id)init {
    self = [super init];
    self.location = nil;
    self.locationManager = [[CLLocationManager alloc] init];
    
    // Get GPS country code
    self.gpsCountry = nil;
    self.locationManager.delegate = self;
    NSUInteger code = [CLLocationManager authorizationStatus];
    if (code == kCLAuthorizationStatusAuthorizedAlways || code == kCLAuthorizationStatusAuthorizedWhenInUse) {
        NSLog(@"Authorization OK");
    }
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
        [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startMonitoringSignificantLocationChanges];
    [self.locationManager startUpdatingLocation];
    
    // Get carrier country code
    CTTelephonyNetworkInfo *network_Info = [CTTelephonyNetworkInfo new];
    CTCarrier *carrier = network_Info.subscriberCellularProvider;
    self.carrierCountry = carrier.isoCountryCode;
    
    // Get locale country code
    NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
    self.langCountry = [currentLocale objectForKey:NSLocaleCountryCode];
    
    return self;
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"%@", error.localizedDescription);
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // If it's a relatively recent event, turn off updates to save power.
    self.location = [locations lastObject];
    CLGeocoder *reverseGeocoder = [[CLGeocoder alloc] init];
    
    [reverseGeocoder reverseGeocodeLocation:self.location completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (error) {
//             DDLogError(@"Geocode failed with error: %@", error);
             return;
         }
         
         CLPlacemark *myPlacemark = [placemarks objectAtIndex:0];
         self.gpsCountry = myPlacemark.ISOcountryCode;
         if (self.gpsCountry.length > 0) {
             [self.listener setCountry:[self getCountryCode]];
         }
     }];
}


- (NSArray *)getAllCountryCodes {
    NSMutableArray *allCodes = [NSMutableArray array];
    if (self.carrierCountry.length > 0) {
        [allCodes addObject:self.carrierCountry];
    }
    if (self.gpsCountry.length > 0 && [allCodes indexOfObject:self.gpsCountry] == NSNotFound) {
        [allCodes addObject:self.gpsCountry];
    }
    NSString *regCountry = [[NSUserDefaults standardUserDefaults] stringForKey:@"countryCode"];
    if (regCountry.length > 0 && [allCodes indexOfObject:regCountry] == NSNotFound) {
        [allCodes addObject:regCountry];
    }
    if (self.langCountry.length > 0 && [allCodes indexOfObject:self.langCountry] == NSNotFound) {
        [allCodes addObject:self.langCountry];
    }
    return allCodes;
}

- (NSString *)getCountryCode {
    // 1. try to get from the carrier
    if (self.carrierCountry.length > 0) return self.carrierCountry;
    // 2. try to get from the GPS
    if (self.gpsCountry.length > 0) return self.gpsCountry;
    // 3. Get from the original registration
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *regCountry = [userDefaults stringForKey:@"countryCode"];
    if  (regCountry.length > 0) {
        return regCountry;
    }
    // 4. Get from the locale
    return self.langCountry;
}

- (void)getCountryCode:(NSObject <LocationListener> *)pListener {
    self.listener = pListener;
    [self.listener setCountry:[self getCountryCode]];
    
}

- (NSArray *)fullPhones:(NSString *)phone {
    NSError *aError = nil;
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSMutableArray *myNumbers = [NSMutableArray array];
    if ([phone hasPrefix:@"+"]) {
        [myNumbers addObject:[phoneUtil parseWithPhoneCarrierRegion:phone error:&aError]];
    } else {
        for (NSString *countryCode in [self getAllCountryCodes]) {
            NBPhoneNumber *tmp = [phoneUtil parse:phone defaultRegion:countryCode error:&aError];
            if (aError == nil && [phoneUtil isValidNumber:tmp]) {
                [myNumbers addObject:tmp];
            }

        }
    }
    
    NSMutableArray *formattedNums = [NSMutableArray array];
    for (NBPhoneNumber *myNumber in myNumbers) {
        NSString *formattedNum = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164
                                                 error:&aError];
        if ([formattedNum hasPrefix:@"+"]) {
            formattedNum = [formattedNum substringFromIndex:1];
        }
        [formattedNums addObject:formattedNum];
    }
    return formattedNums;
}

@end
