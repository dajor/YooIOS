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
    [self.locationManager startMonitoringSignificantLocationChanges];
    
    // Get carrier country code
    CTTelephonyNetworkInfo *network_Info = [CTTelephonyNetworkInfo new];
    CTCarrier *carrier = network_Info.subscriberCellularProvider;
    self.carrierCountry = carrier.isoCountryCode;
    
    // Get locale country code
    NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
    self.langCountry = [currentLocale objectForKey:NSLocaleCountryCode];
    
    return self;
}



- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // If it's a relatively recent event, turn off updates to save power.
    self.location = [locations lastObject];
    CLGeocoder *reverseGeocoder = [[CLGeocoder alloc] init];
    
    [reverseGeocoder reverseGeocodeLocation:self.location completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (error) {
             DDLogError(@"Geocode failed with error: %@", error);
             return;
         }
         
         CLPlacemark *myPlacemark = [placemarks objectAtIndex:0];
         self.gpsCountry = myPlacemark.ISOcountryCode;
         if (self.gpsCountry.length > 0) {
             [self.listener setCountry:[self getCountryCode]];
         }
     }];
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

- (NSString *)fullPhone:(NSString *)phone {
    NSError *aError = nil;
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NBPhoneNumber *myNumber;
    if ([phone hasPrefix:@"+"]) {
        myNumber = [phoneUtil parseWithPhoneCarrierRegion:phone error:&aError];
        phone = [phone substringFromIndex:1];
    } else {
        myNumber = [phoneUtil parse:phone defaultRegion:[self getCountryCode] error:&aError];
    }
    
    
    if (aError == nil) {
        if ([phoneUtil isValidNumber:myNumber]) {
            NSString *formattedNum = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164
                                                 error:&aError];
            if ([formattedNum hasPrefix:@"+"]) {
                formattedNum = [formattedNum substringFromIndex:1];
            }
            return formattedNum;
        }
    }
    return nil;
}

@end
