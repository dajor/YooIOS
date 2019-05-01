//
//  BaseVC.m
//  Yoo
//
//  Created by Arnaud on 06/01/2015.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import "BaseVC.h"
#import "UITools.h"
#import "ChatTools.h"
#import "ContactManager.h"

@interface BaseVC ()

@end

@implementation BaseVC

- (id)initWithTitle:(NSString *)pTitle {
    self = [super init];
    self.title = pTitle;
    self.leftBtn = nil;
    self.rightBtn = nil;
    self.subtitle = nil;
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}


- (void)cancel {
    if ([self.class conformsToProtocol:@protocol(ChatListener)]) {
        [[ChatTools sharedInstance] removeListener:(NSObject<ChatListener> *)self];
    }
    if ([self.class conformsToProtocol:@protocol(ContactListener)]) {
        [[ContactManager sharedInstance] removeListener:(NSObject<ContactListener> *)self];
    }

    [self.navigationController popViewControllerAnimated:YES];
}


- (void)loadView {
    UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [mainView setBackgroundColor:[UIColor whiteColor]];
    [self setView:mainView];
    
    UIView *statusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mainView.frame.size.width, STATUS_HEIGHT)];
    [statusView setBackgroundColor:[UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1]];
    [statusView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
    [mainView addSubview:statusView];
    
    if (self.translucent) {
        self.titleView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, STATUS_HEIGHT, mainView.frame.size.width, HEADER_HEIGHT)];
    } else {
        self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, STATUS_HEIGHT, mainView.frame.size.width, HEADER_HEIGHT)];
        [self.titleView setBackgroundColor:[UITools greenColor]];
    }
    
    [self.titleView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
    [mainView addSubview:self.titleView];
    
    self.titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, self.titleView.frame.size.width - 100, self.titleView.frame.size.height - (self.subtitle != nil ? 18 : 0))];
    [self.titleLbl setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
    [self.titleLbl setFont:[UIFont fontWithName:@"Avenir-Heavy" size:20]];
    [self.titleLbl setTextColor:self.translucent ? [UIColor colorWithWhite:0 alpha:0.7] : [UIColor whiteColor]];
    [self.titleLbl setTextAlignment:NSTextAlignmentCenter];
    [self.titleLbl setText:self.title];
    [self.titleView addSubview:self.titleLbl];
    
    if (self.subtitle != nil) {
        self.subLbl = [[UILabel alloc] initWithFrame:CGRectMake(50, 24, self.titleView.frame.size.width - 100, 18)];
        [self.subLbl setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
        [self.subLbl setFont:[UIFont fontWithName:@"Avenir" size:12]];
        [self.subLbl setTextColor:self.translucent ? [UIColor colorWithWhite:0 alpha:0.5] : [UIColor whiteColor]];
        [self.subLbl setTextAlignment:NSTextAlignmentCenter];
        [self.subLbl setText:self.subtitle];
        [self.titleView addSubview:self.subLbl];
    }

    if (self.navigationController.viewControllers.count > 1) {
        self.leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.leftBtn setImage:[UIImage imageNamed:self.translucent ? @"arrow-black-64.png" : @"arrow-64.png"] forState:UIControlStateNormal];
        [self.leftBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        if (self.translucent) {
            self.leftBtn.alpha = 0.5;
        }
    }
    

    
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.leftBtn != nil) {
        [self.leftBtn setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin];
        [self.leftBtn setFrame:CGRectMake(4, 0, 44, 44)];
        [self.leftBtn setImageEdgeInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
        [self.titleView addSubview:self.leftBtn];
    }
    
    if (self.rightBtn != nil) {
        [self.rightBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleBottomMargin];
        [self.rightBtn setFrame:CGRectMake(self.titleView.frame.size.width - 48, 0, 44, 44)];
        [self.rightBtn setImageEdgeInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
        [self.titleView addSubview:self.rightBtn];
    }
}

- (void)updateHeader {
    [self.titleLbl setText:self.title];
    [self.subLbl setText:self.subtitle];
}


- (CGRect)contentRect {
    return CGRectMake(0, HEADER_HEIGHT + STATUS_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - HEADER_HEIGHT - STATUS_HEIGHT);
}

@end
