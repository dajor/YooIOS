//
//  RecordSoundVC.m
//  Yoo
//
//  Created by Arnaud on 09/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "RecordSoundVC.h"

@interface RecordSoundVC ()

@end

@implementation RecordSoundVC

- (id)initWithListener:(NSObject <RecordListener> *)pListener
{
    self = [super initWithTitle:NSLocalizedString(@"RECORD_MESSAGE", nil)];
    if (self) {
        self.listener = pListener;
        
        NSArray *pathComponents = [NSArray arrayWithObjects:
                                   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                                   @"Recording.m4a",
                                   nil];
        self.recordingUrl = [NSURL fileURLWithPathComponents:pathComponents];
        
        
        // Setup audio session
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
        // Define the recorder setting
        NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
        
        [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
        [recordSetting setValue:[NSNumber numberWithFloat:16000.0] forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
        
        // Initiate and prepare the recorder
        self.recorder = [[AVAudioRecorder alloc] initWithURL:self.recordingUrl settings:recordSetting error:NULL];
        self.recorder.delegate = self;
        self.recorder.meteringEnabled = YES;
        [self.recorder prepareToRecord];
        
        
        self.leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.leftBtn setImage:[UIImage imageNamed:@"arrow-64.png"] forState:UIControlStateNormal];
        [self.leftBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        
        
        self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.rightBtn setTitle:NSLocalizedString(@"DONE", nil) forState:UIControlStateNormal];
        [self.rightBtn addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)send {
    self.duration = [self recordTime];
    [self.recorder stop];
    
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}



- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag {
    [self.listener didRecord:[NSData dataWithContentsOfURL:self.recordingUrl] duration:self.duration];
}

- (void)cancel {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadView {
    [super loadView];
    
    UIView *centerView = [[UIView alloc] initWithFrame:CGRectMake(8, 160, 304, 144)];
    [centerView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin];
    [self.view addSubview:centerView];
    
    self.durationLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 304, 32)];
    [self.durationLbl setTextAlignment:NSTextAlignmentCenter];
    [self.durationLbl setFont:[UIFont systemFontOfSize:[UIFont buttonFontSize] * 1.5]];
    [self.durationLbl setText:@"0:00:000"];
    [centerView addSubview:self.durationLbl];
    
    self.circleBtn = [[RecordButton alloc] initWithFrame:CGRectMake(104, 48, 96, 96)];
    [self.circleBtn setBackgroundColor:[UIColor clearColor]];
    [self.circleBtn setOpaque:NO];
    [centerView addSubview:self.circleBtn];
    
    UIButton *recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [recordBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:[UIFont buttonFontSize]]];
    [recordBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [recordBtn setTitle:NSLocalizedString(@"RECORD_BUTTON", nil) forState:UIControlStateNormal];
    [recordBtn.titleLabel setAdjustsFontSizeToFitWidth:YES];
    [recordBtn setFrame:CGRectMake(112, 72, 80, 48)];
    [recordBtn addTarget:self action:@selector(startRecord:) forControlEvents:UIControlEventTouchUpInside];
    [centerView addSubview:recordBtn];
    
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self
                                   selector:@selector(checkTime) userInfo:nil repeats:YES];
}

- (NSString *)recordTime {
    NSTimeInterval current = self.recorder.currentTime;
    NSInteger millis = ((NSInteger)(current * 1000)) % 1000;
    NSInteger seconds = ((NSInteger)current) % 60;
    NSInteger minutes = ((NSInteger)current) / 60;
    return [NSString stringWithFormat:@"%ld:%02ld:%03ld", (long)minutes, (long)seconds, (long)millis];
}


- (void)checkTime {
    [self.durationLbl setText:[self recordTime]];
}




- (void)startRecord:(id)sender {
    UIButton *recordBtn = (UIButton *)sender;
    if (!self.recorder.recording) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        // Start recording
        [self.recorder record];
        [recordBtn setTitle:NSLocalizedString(@"PAUSE_BUTTON", nil) forState:UIControlStateNormal];

        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.duration = 0.5;
        scaleAnimation.repeatCount = HUGE_VAL;
        scaleAnimation.autoreverses = YES;
        scaleAnimation.fromValue = [NSNumber numberWithFloat:1.1];
        scaleAnimation.toValue = [NSNumber numberWithFloat:0.9];
        
        [self.circleBtn.layer addAnimation:scaleAnimation forKey:@"scale"];
        
    } else {
        
        // Pause recording
        [self.recorder pause];
        [recordBtn setTitle:NSLocalizedString(@"RECORD_BUTTON", nil) forState:UIControlStateNormal];
        
        [self.circleBtn.layer removeAllAnimations];
    }

}

@end
