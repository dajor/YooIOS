//
//  AppDelegate.h
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPStream.h"
#import "Harpy.h"
#import "Reachability.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate>{
    Reachability* internetReachable;
}

@property (assign) BOOL internetActive;
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) NSString *deviceToken;

@end
