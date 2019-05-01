//
//  SecondViewController.h
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatListener.h"
#import "PicklistListener.h"
#import "YooRecipient.h"
#import "ImageListListener.h"
#import "LocationListListener.h"
#import "RecordListener.h"
#import <AVFoundation/AVFoundation.h>
#import <MapKit/MKMapView.h>

#import "BaseVC.h"
#import "Contact.h"


#define FOOTER_SIZE 44
#define BUBBLE_MARGIN 8

typedef NS_ENUM(NSInteger, ChatMode) {
    cmChat,
    cmGroup,
    cmBroadcast
};


@interface ChatVC : BaseVC<ChatListener, UITextViewDelegate, UIActionSheetDelegate, PicklistListener, ImageListListener, LocationListListener, MKMapViewDelegate, RecordListener, AVAudioPlayerDelegate, UIAlertViewDelegate, UIScrollViewDelegate>

- (id)initWithMode:(ChatMode)pMode recipient:(NSObject<YooRecipient> *)pRecipient;

@property (assign) BOOL moreMessages;
@property (assign) int messageCount;
@property (assign) ChatMode mode;
@property (nonatomic, retain) Contact *contact;
@property (nonatomic, retain) NSObject<YooRecipient> *recipient;
@property (nonatomic, retain) UIToolbar *footerView;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) NSArray *msgHeight;
@property (nonatomic, retain) NSString *thread;
@property (nonatomic, retain) UILabel *placeHolder;
@property (nonatomic, retain) NSArray *messages;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, retain) YooMessage *forwarded;
@property (nonatomic, retain) UIButton *callButton;
@property (assign) BOOL isPaused;
@property (assign) BOOL shouldStartCall;
@property (assign) NSTimeInterval curTime;
@property (nonatomic, retain) YooMessage *oldMessage;
@property (nonatomic, retain) NSMutableDictionary *bubbles;

@end
