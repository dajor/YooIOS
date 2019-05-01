//
//  AudioRouter.h
//  Yoo
//
//  Created by raksmey yorn on 1/10/2015.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioRouter : NSObject
+ (void) initAudioSessionRouting;
+ (void) switchToDefaultHardware;
+ (void) forceOutputToBuiltInSpeakers;
@end
