//
//  RecordSoundVC.h
//  Yoo
//
//  Created by Arnaud on 09/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "RecordButton.h"
#import "RecordListener.h"

@interface RecordSoundVC : UIViewController<AVAudioRecorderDelegate>

@property (nonatomic, retain) AVAudioRecorder *recorder;
@property (nonatomic, retain) RecordButton *circleBtn;
@property (nonatomic, retain) UILabel *durationLbl;
@property (nonatomic, retain) NSURL *recordingUrl;
@property (nonatomic, retain) NSObject<RecordListener> *listener;
@property (nonatomic, retain) NSString *duration;

- (id)initWithListener:(NSObject <RecordListener> *)pListener;

@end
