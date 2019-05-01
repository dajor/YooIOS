//
//  WebserviceRequestListener.h
//  Yoo
//
//  Created by Heng Sokchamroeun on 10/15/14.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

@protocol WebserviceRequestListener <NSObject>
    -(void) onSuccess:(id)request result:(NSDictionary *) result;
    -(void) onFailure:(id)request result:(NSDictionary *) result;
@end