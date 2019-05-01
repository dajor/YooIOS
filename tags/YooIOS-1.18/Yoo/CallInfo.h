//
//  CallInfo.h
//  Yoo
//
//  Created by Arnaud on 27/02/2015.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PhoneCallStep) {
    pcReceivedConferenceNumber,
    pcCallRequest,
    pcCallAccepted,
    pcCallRejected
};

@interface CallInfo : NSObject

@property (assign) NSInteger step;
@property (nonatomic, retain) NSString *confNumber;
@property (nonatomic, retain) NSString *caller;
@property (nonatomic, retain) NSString *callMsgId;

- (id)initWithStep:(PhoneCallStep)step number:(NSString *)confNumber;

@end
