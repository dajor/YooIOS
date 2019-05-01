//
//  YooMessage.h
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YooUser.h"
#import "YooGroup.h"
#import <CoreLocation/CLLocation.h>
#import "Contact.h"

typedef NS_ENUM(NSInteger, YooMessageType) {
    // IMPORTANT : add the new types at the end
    // to keep the same numbers assigned to the types (0,1,2,3..)
    ymtText, // 0
    ymtPicture, // 1
    ymtLocation, // 2
    ymtContact, // 3
    ymtAck, // 4
    ymtInvite, // 5
    ymtRevoke, // 6
    ymtSound, // 7
    ymtCallRequest, // 8
    ymtCallStatus // 9
};


typedef NS_ENUM(NSInteger, CallStatus) {
    csNone,
    //csReceivedConferenceNumber,
    //csRequested,
    csAccepted,
    csRejected,
    csCancelled
};


@interface YooMessage : NSObject

@property (assign) YooMessageType type;
@property (nonatomic, retain) NSString *yooId;
@property (nonatomic, retain) NSString *ident;
@property (nonatomic, retain) NSObject<YooRecipient> *from;
@property (nonatomic, retain) NSObject<YooRecipient> *to;
@property (nonatomic, retain) NSNumber *shared;
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) NSString *thread;
@property (nonatomic, retain) NSArray *pictures;
@property (nonatomic, retain) NSData *sound;
@property (nonatomic, retain) NSString *conferenceNumber;
@property (assign) CallStatus callStatus;
@property (nonatomic, retain) NSString *callReqId;
@property (assign) CLLocationCoordinate2D location;
@property (assign) BOOL read;
@property (assign) BOOL ack;
@property (assign) BOOL sent;
@property (assign) BOOL receipt;
@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) YooGroup *group;

- (NSString *)toDisplay;

@end
