//
//  WebserviceRequest.h
//  Yoo
//
//  Created by Heng Sokchamroeun on 10/15/14.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebserviceRequestListener.h"
@interface WebserviceRequest : NSObject
    @property (nonatomic, retain) NSURLConnection *theConnection;
    @property (nonatomic, retain) NSObject<WebserviceRequestListener> *listener;
    @property (nonatomic, retain) NSMutableData *webData;
    @property (nonatomic, retain) NSNumber *status;
-(void) doRequest:(WebserviceRequest *) pListener name:(NSString *) pName country:(NSString *)pCountry type:(NSString *)pType action:(NSString *)pAction listNames:(NSArray *)pListNames;
@end
