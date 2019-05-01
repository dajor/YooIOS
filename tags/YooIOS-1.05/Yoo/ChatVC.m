//
//  SecondViewController.m
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "ChatVC.h"
#import "ContactListVC.h"
#import "ChatTools.h"
#import "UITools.h"
#import "TriangleView.h"
#import <MapKit/MKMapView.h>
#import <MapKit/MKPointAnnotation.h>
#import "LocationTools.h"
#import "ChatDAO.h"
#import "GroupDAO.h"
#import "ImageTools.h"
#import "UserDAO.h"
#import "ContactManager.h"
#import "PictureVC.h"
#import "ImageListVC.h"
#import "LocationListVC.h"
#import "RecordSoundVC.h"
#import "YooBroadcast.h"
#import "ContactDetailVC.h"
#import "ContactDAO.h"

@interface ChatVC ()

@end

@implementation ChatVC

- (id)initWithMode:(ChatMode)pMode recipient:(NSObject<YooRecipient> *)pRecipient {
    self = [super init];
    self.mode = pMode;
    self.recipient = pRecipient;
    self.msgHeight = nil;
    self.thread = nil;
    self.title = nil;
    if (self.mode == cmGroup) {
        self.title = ((YooGroup *)self.recipient).alias;
    } else if (self.mode == cmChat) {
        YooUser *yooUser = (YooUser *)self.recipient;
        self.contact = [ContactDAO find:yooUser.contactId];
        self.title = self.contact.fullName;
    } else if (self.mode == cmBroadcast) {
        self.title = self.title = NSLocalizedString(@"BROADCAST", nil);
    }
    [[ChatTools sharedInstance] addListener:self];
    [UITools setupTitleBar];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    
    if (self.mode == cmGroup) {
        YooGroup *group = (YooGroup *)self.recipient;
        NSString *prefix = [NSString stringWithFormat:@"%@-", [ChatTools sharedInstance].login];
        if ([[group toJID] hasPrefix:prefix]) {
            [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editGroup)]];
        } else {
            [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"VIEW", nil) style:UIBarButtonItemStylePlain target:self action:@selector(editGroup)]];
        }
    }
    if (self.mode == cmChat) {
        UIImage *image = [UIImage imageWithData:((YooUser *)self.recipient).picture];
        UIButton *innerBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
        [innerBtn setImage:image forState:UIControlStateNormal];
        innerBtn.imageView.layer.cornerRadius = 18;
        innerBtn.imageView.layer.masksToBounds = YES;
        [innerBtn addTarget:self action:@selector(viewContact) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:innerBtn];

        [self.navigationItem setRightBarButtonItem:barBtn];
    }
    
    if (self.mode == cmBroadcast) {
        // delete previous broadcasts
        [ChatDAO deleteForRecipient:BROADCAST_CODE];
    }
    
    return self;
}

- (void)dealloc {
    [[ChatTools sharedInstance] removeListener:self];
}

- (void)loadView {
    
    UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    UIImageView *bgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, mainView.frame.size.width, mainView.frame.size.height)];
    [bgView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    NSString *bgName = [[NSUserDefaults standardUserDefaults] stringForKey:@"background"];

    [bgView setImage:[UIImage imageNamed:bgName]];
    [bgView setContentMode:UIViewContentModeScaleToFill];
    [mainView addSubview:bgView];
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, mainView.frame.size.width, mainView.frame.size.height - ([UITools isIOS7] ? 0 : FOOTER_SIZE))];
    [self.scrollView setContentInset:UIEdgeInsetsMake([UITools isIOS7] ? 64 : 0, 0, [UITools isIOS7] ? FOOTER_SIZE : 0, 0)];
    [self.scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   // [self.scrollView setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    [self.scrollView setBackgroundColor:[UIColor clearColor]];
    
    [mainView addSubview:self.scrollView];

    self.footerView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, mainView.frame.size.height - FOOTER_SIZE, mainView.frame.size.width, FOOTER_SIZE)];
//    self.footerView.barStyle = UIBarStyleBlackTranslucent;
    [self.footerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];
//    self.footerView = [[UIView alloc] initWithFrame:CGRectMake(0, mainView.frame.size.height - FOOTER_SIZE, mainView.frame.size.width, FOOTER_SIZE)];
//    [self.footerView setBackgroundColor:[UIColor whiteColor]];

    UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [sendBtn setFrame:CGRectMake(self.footerView.frame.size.width - 48, 4, 44, self.footerView.frame.size.height - 8)];
    [sendBtn setTitle:NSLocalizedString(@"CHAT_SEND", nil) forState:UIControlStateNormal];
    [sendBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [sendBtn addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:sendBtn];
    
    UIButton *attachBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [attachBtn setImageEdgeInsets:UIEdgeInsetsMake(4,8,4,8)];
    [attachBtn setFrame:CGRectMake(4, 4, 44, self.footerView.frame.size.height - 8)];
    [attachBtn setImage:[UIImage imageNamed:@"clip.png"] forState:UIControlStateNormal];
    [attachBtn setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
    [attachBtn addTarget:self action:@selector(postItem:) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:attachBtn];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(52, 6, self.footerView.frame.size.width - 104, self.footerView.frame.size.height - 12)];
    [self.textView setBackgroundColor:[UIColor whiteColor]];
    //[self.textField setBorderStyle:UITextBorderStyleRoundedRect];
    [self.textView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    //self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    //self.textField.placeholder = @"What's up?";
    self.textView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    self.textView.returnKeyType = UIReturnKeyDefault;
    self.textView.delegate = self;
    self.textView.layer.borderWidth = 1;
    self.textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.textView.layer.cornerRadius = 4;
    self.placeHolder = [[UILabel alloc] initWithFrame:CGRectMake(4, 4, self.textView.frame.size.width - 8, self.textView.frame.size.height - 8)];
    [self.placeHolder setFont:self.textView.font];
    [self.placeHolder setTextColor:[UIColor lightGrayColor]];
    [self.placeHolder setText:NSLocalizedString(@"CHAT_PROMPT", nil)];
    [self.textView addSubview:self.placeHolder];
    [self.footerView addSubview:self.textView];
    
    [mainView addSubview:self.footerView];
    [self setView:mainView];
    
}

- (void)viewWillAppear:(BOOL)animated {
    if (![UITools isIOS7]) {
        [self adjustContentSize];
    }

    [self buildTitleView:[[UIApplication sharedApplication] statusBarOrientation]];
    
    
    [self update];
    // mark all messages as read
    [[ChatTools sharedInstance] markAsRead:self.recipient];
    
    NSInteger unread = [ChatDAO unreadCount];
    [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:unread > 0 ? [NSString stringWithFormat:@"%ld", (long)unread] : nil];
}

- (void)viewDidAppear:(BOOL)animated {
    // the code below is for preventing a flash that occurs because of the footerview,
    // when pushing a view controller on iOS7.
    if ([UITools isIOS7] && self.navigationController.childViewControllers.count > 1) {
        [UIView animateWithDuration:.1 animations:^{
            [self.footerView setFrame:CGRectMake(0, self.footerView.frame.origin.y, self.view.frame.size.width, FOOTER_SIZE)];
        }];
    }
    [self hideTabBar];
}


- (void)viewWillDisappear:(BOOL)animated {
    // the code below is for preventing a flash that occurs because of the footerview,
    // when pushing a view controller on iOS7.
    if ([UITools isIOS7] && self.navigationController.childViewControllers.count > 1) {
        [UIView animateWithDuration:.1 animations:^{
            [self.footerView setFrame:CGRectMake(-self.view.frame.size.width, self.footerView.frame.origin.y, self.view.frame.size.width, FOOTER_SIZE)];
        }];
    }
    [super viewWillDisappear:animated];
    [self showTabBar];

}

- (void)adjustContentSize {
    UITabBar *tabBar = self.tabBarController.tabBar;
    UIView *parent = tabBar.superview; // UILayoutContainerView
    UIView *content = [parent.subviews objectAtIndex:0];  // UITransitionView
    UIView *window = parent.superview;
    if (window == nil) {
        window = [UIApplication sharedApplication].keyWindow;
    }
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        content.frame = CGRectMake(0, 0, window.bounds.size.height, window.bounds.size.width);
    } else {
        content.frame = window.bounds;
    }
}

- (void)hideTabBar {
    UITabBar *tabBar = self.tabBarController.tabBar;
    UIView *parent = tabBar.superview; // UILayoutContainerView
    UIView *window = parent.superview;
    [UIView animateWithDuration:0.5
                     animations:^{
                         CGRect tabFrame = tabBar.frame;
                         tabFrame.origin.y = CGRectGetMaxY(window.bounds);
                         tabBar.frame = tabFrame;
                     }];
    
    // 1
}

- (void)showTabBar {
    UITabBar *tabBar = self.tabBarController.tabBar;
    UIView *parent = tabBar.superview; // UILayoutContainerView
    UIView *content = [parent.subviews objectAtIndex:0];  // UITransitionView
    UIView *window = parent.superview;
    
    [UIView animateWithDuration:0.5
                     animations:^{
                         CGRect tabFrame = tabBar.frame;
                         if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
                             tabFrame.origin.y = window.bounds.size.width - CGRectGetHeight(tabBar.frame);
                         } else {
                             tabFrame.origin.y = CGRectGetMaxY(window.bounds) - CGRectGetHeight(tabBar.frame);
                         }
                         tabBar.frame = tabFrame;
                         if (![UITools isIOS7]) {
                             CGRect contentFrame = content.frame;
                             contentFrame.size.height -= tabFrame.size.height;
                             content.frame = contentFrame;
                         }
                     }];
    
    // 2
}

- (void)viewDidLayoutSubviews {
    [self scrollDown:NO];
}

- (void)scrollDown:(BOOL)animated {

    CGFloat y = self.scrollView.contentSize.height;
    int visibleHeight = self.scrollView.frame.size.height - self.scrollView.contentInset.top - self.scrollView.contentInset.bottom;
    if (y > visibleHeight) {
        CGPoint bottomOffset = CGPointMake(0, - self.scrollView.contentInset.top + y - visibleHeight);
        if ([[ChatTools sharedInstance] messagesForRecipient:self.recipient withPicture:NO].count == MAX_USER_HISTORY) {
            int height = [[self.msgHeight lastObject] intValue];
            [self.scrollView setContentOffset:CGPointMake(0, bottomOffset.y - height) animated:NO];
        }
        [self.scrollView setContentOffset:bottomOffset animated:animated];
    }
}



- (void)update {
    // clear all the existing
    for (UIView *child in [self.scrollView subviews]) {
        [child removeFromSuperview];
    }
    int y = BUBBLE_MARGIN;
    self.messages = [[ChatTools sharedInstance] messagesForRecipient:self.recipient withPicture:YES];

    UIFont *messageFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    NSMutableArray *tmp = [NSMutableArray array];
    
    NSString *currentDate = nil;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterLongStyle];
    NSDateFormatter *tf = [[NSDateFormatter alloc] init];
    [tf setTimeStyle:NSDateFormatterShortStyle];
    
    int i = 0;
    for (YooMessage *yooMsg in self.messages) {
        
        NSString *msgDate = [df stringFromDate:yooMsg.date];
        if (currentDate == nil || ![msgDate isEqualToString:currentDate]) {
            CGSize textSize = [msgDate sizeWithFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];
            
            UILabel *dateLbl = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - textSize.width/2 - BUBBLE_MARGIN, y, textSize.width + BUBBLE_MARGIN*2, 16)];
            [dateLbl setText:msgDate];
            [dateLbl setFont:[UIFont systemFontOfSize:[UIFont smallSystemFontSize]]];
            [dateLbl setTextColor:[UIColor whiteColor]];
            [dateLbl setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:0.5]];
            dateLbl.layer.cornerRadius = 8;
            dateLbl.layer.masksToBounds = YES;
            [dateLbl setTextAlignment:NSTextAlignmentCenter];
            [self.scrollView addSubview:dateLbl];
            currentDate = msgDate;
            y += 16 + BUBBLE_MARGIN;
        }
        
        NSInteger leftMargin = self.mode == cmGroup && ![yooMsg.from isMe] ? 4 * BUBBLE_MARGIN : 0;
        
        CGSize constraintSize = CGSizeMake(self.view.frame.size.width - leftMargin - BUBBLE_MARGIN * 6, MAXFLOAT);
        CGSize size;
        UIColor *bubbleColor = [yooMsg.from isMe] ? [UIColor colorWithRed:1.0 green:1.0 blue:0.9 alpha:1.0] : [UIColor whiteColor];
        // compute message
        NSString *displayedText = yooMsg.message;
        if (yooMsg.type == ymtContact) {
            Contact *contact = [[ContactManager sharedInstance] find:[yooMsg.shared integerValue]];
            displayedText = [NSString stringWithFormat:[yooMsg.from isMe] ? NSLocalizedString(@"SHARED_CONTACT", nil) : NSLocalizedString(@"RECEIVED_CONTACT", nil), contact.fullName];
            bubbleColor = [UIColor colorWithRed:0.9 green:1 blue:0.9 alpha:1.0];
        }
        if (yooMsg.type == ymtSound) {
            bubbleColor = [UIColor colorWithRed:0.95 green:1 blue:0.95 alpha:1.0];
        }
        if (yooMsg.type == ymtCallRequest){
            bubbleColor = [UIColor colorWithRed:0.95 green:1 blue:0.95 alpha:1.0];
        }

        // compute size
        if (yooMsg.type == ymtLocation) {
            size = CGSizeMake(constraintSize.width, constraintSize.width);
        } else if (yooMsg.type == ymtPicture) {
            NSInteger totalHeight = 0;
            NSInteger maxWidth = 0;
            for (NSData *picData in yooMsg.pictures) {
                if (totalHeight > 0) {
                    totalHeight += BUBBLE_MARGIN;
                }
                UIImage *picture = [UIImage imageWithData:picData];
                CGSize tmp = picture.size;
                if (tmp.width > constraintSize.width) {
                    tmp = CGSizeMake(constraintSize.width, tmp.height * constraintSize.width / tmp.width);
                }
                totalHeight += tmp.height;
                if (tmp.width > maxWidth) {
                    maxWidth = tmp.width;
                }
            }
            size = CGSizeMake(maxWidth, totalHeight);
        } else if (yooMsg.type == ymtSound) {
            size = CGSizeMake(128, 44);
        } else if(yooMsg.type == ymtCallRequest){
            size = CGSizeMake(128, 44);
        }else {
            size = [UITools getStringSize:displayedText font:messageFont constraint:constraintSize];
        }
        // increase size in group chat to display the sender's name
        CGFloat bubbleTop = 0, bubbleBottom = 0, bubbleRight = 0;
        YooUser *groupMember = nil;
        if (![yooMsg.from isMe] && self.mode == cmGroup) {
            
            // if the user name is longer than the message, increase the size
            groupMember = [UserDAO find:((YooGroup *)yooMsg.from).member domain:YOO_DOMAIN];
            CGSize userSize = [UITools getStringSize:groupMember.alias font:messageFont constraint:constraintSize];
            bubbleTop = userSize.height + BUBBLE_MARGIN;
            if (userSize.width > size.width) {
                size = CGSizeMake(userSize.width, size.height);
            }
        }
        // compute size of the last line
        NSString *dateTxt = [tf stringFromDate:yooMsg.date];
        CGSize dateSize = [UITools getStringSize:dateTxt font:[UIFont systemFontOfSize:10] constraint:CGSizeMake(MAXFLOAT, MAXFLOAT)];
        dateSize = CGSizeMake(dateSize.width + 4, dateSize.height);
        if ([yooMsg.from isMe]) {
            dateSize = CGSizeMake(dateSize.width + 15, dateSize.height);
        }
        if (yooMsg.type == ymtText || yooMsg.type == ymtContact) {
            NSMutableString *lastLine = nil;
            NSInteger lineCount = 0;
            CGSize tmpSize = CGSizeZero, prevSize = CGSizeZero;
            for (NSInteger i = 0; i < displayedText.length; i++) {
                tmpSize = [UITools getStringSize:[displayedText substringToIndex:i+1] font:messageFont constraint:size];
                if (tmpSize.height > prevSize.height) {
                    lastLine = [[NSMutableString alloc] init];
                    lineCount++;
                }
                [lastLine appendFormat:@"%c", [displayedText characterAtIndex:i]];
                prevSize = tmpSize;
            }

            CGSize lastLineSize = [UITools getStringSize:lastLine font:messageFont constraint:constraintSize];
            if (size.width - lastLineSize.width < dateSize.width) {
                // try to increase the width, if possible
                if (/*lineCount == 1 && */size.width < constraintSize.width && lastLineSize.width + dateSize.width < constraintSize.width) {
                    bubbleRight = lastLineSize.width + dateSize.width - size.width;
                } else {
                    // if not possible, increase the height
                    bubbleBottom = dateSize.height - 4;
                }
            }
        } else {
            // not text messages : always add the date at the bottom
           
        }
        
        // build the bubble containing the message
        CGFloat bx = BUBBLE_MARGIN * 2 + leftMargin;
        if ([yooMsg.from isMe]) {
            bx = self.view.frame.size.width - size.width - BUBBLE_MARGIN*4 - bubbleRight;
        }
        UIView *bubble = [[UIView alloc] initWithFrame:CGRectMake(bx, y, size.width + bubbleRight + BUBBLE_MARGIN * 2, size.height + bubbleTop + bubbleBottom + BUBBLE_MARGIN * 2)];
        bubble.layer.cornerRadius = 4;
        bubble.tag = i;
        [bubble setBackgroundColor:bubbleColor];
        


        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [bubble addGestureRecognizer:longPress];
        
        if (![yooMsg.from isMe] && self.mode == cmGroup) {
            YooUser *yooUser = nil;
            if ([yooMsg.from isMemberOfClass:[YooUser class]]) {
                yooUser = [UserDAO find:((YooUser *)yooMsg.from).name domain:((YooUser *)yooMsg.from).domain];
            } else {
                yooUser = [UserDAO find:((YooGroup *)yooMsg.from).member domain:YOO_DOMAIN];
            }

            UIImage *image = yooUser == nil || yooUser.picture == nil ? [UIImage imageNamed:@"user-icon.png"] : [UIImage imageWithData:yooUser.picture];
            UIImageView *picView = [[UIImageView alloc] initWithImage:image];
            [picView setFrame:CGRectMake(BUBBLE_MARGIN, y, BUBBLE_MARGIN*4, BUBBLE_MARGIN*4)];
            [self.scrollView addSubview:picView];
            
            // add user name
            UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(BUBBLE_MARGIN, BUBBLE_MARGIN/2, size.width, bubbleTop - BUBBLE_MARGIN)];
            [nameLbl setTextColor:[UIColor colorWithWhite:0.6 alpha:1]];
            [nameLbl setText:[groupMember alias]];
            [nameLbl setFont:messageFont];
            [bubble addSubview:nameLbl];
            
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(BUBBLE_MARGIN, bubbleTop + BUBBLE_MARGIN/4, size.width, 1)];
            [separator setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1]];
            [bubble addSubview:separator];
        }
        
        TriangleView *triangle;
        if ([yooMsg.from isMe]) {
            triangle = [[TriangleView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - BUBBLE_MARGIN*2, y + BUBBLE_MARGIN, BUBBLE_MARGIN, BUBBLE_MARGIN) left:NO color:bubbleColor];
        } else {
            triangle = [[TriangleView alloc] initWithFrame:CGRectMake(BUBBLE_MARGIN + leftMargin, y + BUBBLE_MARGIN, BUBBLE_MARGIN, BUBBLE_MARGIN) left:YES color:bubbleColor];
        }
        [triangle setBackgroundColor:[UIColor clearColor]];
        [self.scrollView addSubview:triangle];
        
        if (yooMsg.type == ymtLocation) {
            // create region, consisting of span and location
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(yooMsg.location, 500, 500);
            
            MKMapView *mapView = [[MKMapView alloc] initWithFrame:CGRectMake(BUBBLE_MARGIN, BUBBLE_MARGIN + bubbleTop, size.width, size.height)];
            [mapView setDelegate:self];
            [mapView setRegion:region animated:NO];
            [mapView setUserInteractionEnabled:YES];
            [mapView setScrollEnabled:NO];
            [mapView setZoomEnabled:NO];
            [bubble addSubview:mapView];

            
            MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
            annotationPoint.coordinate = yooMsg.location;
            NSArray *parts = [yooMsg.message componentsSeparatedByString:@"\n"];
            if (parts.count > 0) {
                annotationPoint.title = [parts objectAtIndex:0];
            }
            if (parts.count > 1 && ![yooMsg.message hasPrefix:@"Current Location"]) {
                annotationPoint.subtitle = [parts objectAtIndex:1];
            }
            [mapView addAnnotation:annotationPoint];
            [mapView selectAnnotation:annotationPoint animated:NO];
            
            
        } else if (yooMsg.type == ymtPicture) {
            NSInteger y1 = BUBBLE_MARGIN + bubbleTop;
            for (NSData *data in yooMsg.pictures) {
                UIImage *picture = [UIImage imageWithData:data];
                CGSize tmp = picture.size;
                if (tmp.width > constraintSize.width) {
                    tmp = CGSizeMake(constraintSize.width, tmp.height * constraintSize.width / tmp.width);
                }
                UIImageView *imageView = [[UIImageView alloc] initWithImage:picture];
                [imageView setFrame:CGRectMake(BUBBLE_MARGIN + (size.width - tmp.width) / 2, y1, tmp.width, tmp.height)];
                [bubble addSubview:imageView];
                
                
                UIButton *hiddenButton = [[UIButton alloc] initWithFrame:CGRectMake(BUBBLE_MARGIN, BUBBLE_MARGIN, size.width, size.height)];
                [hiddenButton addTarget:self action:@selector(imageClick:) forControlEvents:UIControlEventTouchUpInside];
                [hiddenButton setTag:i];
                [bubble addSubview:hiddenButton];
                
                y1 += tmp.height + BUBBLE_MARGIN;
            }
            

        } else if (yooMsg.type == ymtSound) {
            UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [playBtn setFrame:CGRectMake(BUBBLE_MARGIN, BUBBLE_MARGIN + bubbleTop, 44, 44)];
            [playBtn setTag:i];
            [playBtn setImage:[UIImage imageNamed:@"audio-file-64.png"] forState:UIControlStateNormal];
            [playBtn addTarget:self action:@selector(playSound:) forControlEvents:UIControlEventTouchUpInside];
            [bubble addSubview:playBtn];
            
            UILabel *durationLbl = [[UILabel alloc] initWithFrame:CGRectMake(BUBBLE_MARGIN*2 + 44, BUBBLE_MARGIN + bubbleTop, size.width - 44 -BUBBLE_MARGIN, size.height)];
            [durationLbl setFont:messageFont];
            [durationLbl setText:displayedText];
            [durationLbl setNumberOfLines:0];
            [durationLbl setLineBreakMode:NSLineBreakByWordWrapping];
            [durationLbl setBackgroundColor:[UIColor clearColor]];
            [bubble addSubview:durationLbl];
        } else if(yooMsg.type == ymtCallRequest){
            UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [playBtn setFrame:CGRectMake(BUBBLE_MARGIN, BUBBLE_MARGIN + bubbleTop, 44, 44)];
            [playBtn setTag:i];
            [playBtn setImage:[UIImage imageNamed:@"phone-48.png"] forState:UIControlStateNormal];
//            [playBtn addTarget:self action:@selector(callPhoneNumber:) forControlEvents:UIControlEventTouchUpInside];
            [bubble addSubview:playBtn];
            
            UILabel *durationLbl = [[UILabel alloc] initWithFrame:CGRectMake(BUBBLE_MARGIN*2 + 44, BUBBLE_MARGIN + bubbleTop, size.width - 44 -BUBBLE_MARGIN, size.height)];
            [durationLbl setFont:messageFont];
            [durationLbl setText:displayedText];
            [durationLbl setNumberOfLines:0];
            [durationLbl setLineBreakMode:NSLineBreakByWordWrapping];
            [durationLbl setBackgroundColor:[UIColor clearColor]];
            [bubble addSubview:durationLbl];
        }else {
            UILabel *msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(BUBBLE_MARGIN, BUBBLE_MARGIN + bubbleTop, size.width, size.height)];
            [msgLabel setFont:messageFont];
            [msgLabel setText:displayedText];
            [msgLabel setNumberOfLines:0];
            [msgLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [msgLabel setBackgroundColor:[UIColor clearColor]];
            [bubble addSubview:msgLabel];
        }
        
        // add the date
        UILabel *dateLbl = [[UILabel alloc] initWithFrame:CGRectMake(bubble.frame.size.width - dateSize.width, bubble.frame.size.height - 2 - dateSize.height, dateSize.width, dateSize.height)];
        [dateLbl setTextColor:[UIColor lightGrayColor]];
        [dateLbl setBackgroundColor:[UIColor clearColor]];
        [dateLbl setFont:[UIFont systemFontOfSize:10]];
        [dateLbl setText:dateTxt];
        [bubble addSubview:dateLbl];
        
        if ([yooMsg.from isMe] && yooMsg.ack) {
            UIImageView *ackImg = [[UIImageView alloc] initWithFrame:CGRectMake(bubble.frame.size.width - 17, bubble.frame.size.height - 1 - dateSize.height, 10, 10)];
            [ackImg setAlpha:0.6];
            [ackImg setImage:[UIImage imageNamed:@"check-mark-64.png"]];
            [bubble addSubview:ackImg];
        }
        if ([yooMsg.from isMe] && yooMsg.sent) {
            UIImageView *sentImg = [[UIImageView alloc] initWithFrame:CGRectMake(bubble.frame.size.width - 12, bubble.frame.size.height - 1 - dateSize.height, 10, 10)];
            [sentImg setAlpha:0.6];
            [sentImg setImage:[UIImage imageNamed:@"check-mark-64.png"]];
            [bubble addSubview:sentImg];
        }

        [self.scrollView addSubview:bubble];
        
        y += size.height + bubbleTop + bubbleBottom + BUBBLE_MARGIN * 3;
        
        [tmp addObject:[NSNumber numberWithInt:size.height + bubbleTop + bubbleBottom + BUBBLE_MARGIN * 3]];
        
        i++;
    }
    if (self.messages.count > 0) {
        self.thread = ((YooMessage *)[self.messages lastObject]).thread;
    }
    self.msgHeight = tmp;
    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width, y)];

}


- (void)didReceiveMessage:(YooMessage *)message {
    // new message received from the other
    if ([message.from.toJID isEqualToString:self.recipient.toJID]) {
        if (self.isViewLoaded && self.view.window) {
            [[ChatTools sharedInstance] markAsRead:self.recipient];
        }
//        if (message.type != ymtCall){
            [self update];
            [self scrollDown:YES];
//        }
    }
    // ack message
    if ([message.from isMe]) {
        [self update];
    }
}

- (void)friendListChanged:(NSArray *)newFriends {
    if (self.mode == cmChat) {
        for (YooUser *user in newFriends) {
            if (user.contactId == self.contact.contactId) {
                self.recipient = [UserDAO find:user.name domain:YOO_DOMAIN]; // re-read the user so we have the last online date
                [self buildTitleView:[[UIApplication sharedApplication] statusBarOrientation]];
                break;
            }
        }
    } else if (self.mode == cmGroup) {
        YooGroup *group = (YooGroup *)self.recipient;
        if ([GroupDAO find:group.name] == nil) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)didLogin:(NSString *)error {
    
}




- (NSInteger)computeKeyboardHeight:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        return kbSize.width;
    } else {
        return kbSize.height;
    }
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSInteger kbHeight = [self computeKeyboardHeight:aNotification];
    [self animateTextField:-kbHeight duration:0.3];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    NSInteger kbHeight = [self computeKeyboardHeight:aNotification];
    [self animateTextField:kbHeight duration:0.1];
}

- (void)textViewDidChange:(UITextView *)textView {
    [self.placeHolder setHidden:textView.text.length > 0];
    // The code below fixed an issue on iOS7 when cursor cannot be seen
    // after the Return key is touched.
    CGRect line = [textView caretRectForPosition:
                   textView.selectedTextRange.start];
    CGFloat overflow = line.origin.y + line.size.height
    - ( textView.contentOffset.y + textView.bounds.size.height
       - textView.contentInset.bottom - textView.contentInset.top );
    if ( overflow > 0 ) {
        // We are at the bottom of the visible text and introduced a line feed, scroll down (iOS 7 does not do it)
        // Scroll caret to visible area
        CGPoint offset = textView.contentOffset;
        offset.y += overflow + 7; // leave 7 pixels margin
        // Cannot animate with setContentOffset:animated: or caret will not appear
        [UIView animateWithDuration:.2 animations:^{
            [textView setContentOffset:offset];
        }];
    }
}

- (void)animateTextField:(NSInteger)dist duration:(CGFloat)duration
{
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: duration];
    self.footerView.frame = CGRectOffset(self.footerView.frame, 0, dist);
    [UIView commitAnimations];
    
    self.scrollView.contentInset = UIEdgeInsetsMake(self.scrollView.contentInset.top, self.scrollView.contentInset.left, self.scrollView.contentInset.bottom - dist, self.scrollView.contentInset.right);
    self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset;
    
    [self scrollDown:YES];
}

- (void)sendMessage {
    NSString *trimmed = [self.textView.text stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length > 0) {
        YooMessage *yooMsg = [self buildNewMessage];
        yooMsg.message = trimmed;
        [self send:yooMsg];
        [self.textView setText:@""];
        [self.placeHolder setHidden:NO];
    }
}

- (void)send:(YooMessage *)yooMsg {
    if (self.mode == cmBroadcast) {
        [[ChatTools sharedInstance] sendMessage:yooMsg];
        YooBroadcast *broadcast = (YooBroadcast *)self.recipient;
        for (NSString *name in broadcast.names) {
            YooUser *yooUser = [UserDAO find:name domain:YOO_DOMAIN];
            yooMsg.to = yooUser;
            [[ChatTools sharedInstance] sendMessage:yooMsg];
        }
    } else {
        [[ChatTools sharedInstance] sendMessage:yooMsg];
    }
    [self update];
    [self scrollDown:YES];
}


- (BOOL)textViewShouldReturn:(UITextView *)textView {
    //[self.textView resignFirstResponder];
    //[self sendMessage];
    return YES;
}

- (void)didReceiveRegistrationInfo:(NSDictionary *)info {
    // do nothing
}

- (void)addressBookChanged {
    // do nothing
}

- (void)didReceiveUserFromPhone:(NSDictionary *)info {
    // do nothing
}

- (void)postItem:(id)sender {
    UIButton *button = (UIButton *)sender;
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"POST_ITEM", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"POST_PICTURES", nil), NSLocalizedString(@"POST_LOCATION", nil), NSLocalizedString(@"POST_CONTACT", nil), NSLocalizedString(@"POST_VOICE", nil), NSLocalizedString(@"POST_CALL", nil), nil];
    [sheet showFromRect:button.frame inView:self.view animated:YES];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { // picture
        ImageListVC *imageVC = [[ImageListVC alloc] initWithListener:self];
        UINavigationController *imageNav = [[UINavigationController alloc] initWithRootViewController:imageVC];
        [self presentViewController:imageNav animated:YES completion:nil];
    } else if (buttonIndex == 1) { // location
        LocationListVC *locVC = [[LocationListVC alloc] initWithListener:self];
        UINavigationController *locNav = [[UINavigationController alloc] initWithRootViewController:locVC];
        [self presentViewController:locNav animated:YES completion:nil];
    } else if (buttonIndex == 2) { // contact
        ContactListVC *contactVC = [[ContactListVC alloc] initWithType:clAddressBookSelect listener:self title:NSLocalizedString(@"SEND_CONTACT", nil) selected:nil];
        contactVC.tag = 0;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVC];
        [self presentViewController:nav animated:YES completion:nil];
    } else if (buttonIndex == 3) {
        RecordSoundVC *recordVC = [[RecordSoundVC alloc] initWithListener:self];
        UINavigationController *recordNav = [[UINavigationController alloc] initWithRootViewController:recordVC];
        [self presentViewController:recordNav animated:YES completion:nil];
    } else if (buttonIndex == 4){
        // Button Call
        // [self didCall];
        NSMutableArray *members = [NSMutableArray array];
        if (self.mode == cmGroup){
            YooGroup *group = (YooGroup *)self.recipient;
            for (NSString *userJid in [GroupDAO listMembers:group.toJID]) {
                YooUser *user = [UserDAO findByJid:userJid];
                if (user != nil) {
                    [members addObject:user];
                }
            }
        }else if(self.mode == cmChat){
            YooUser *user = (YooUser *)self.recipient;
            [members addObject:user];
        }
        if([members count] > 0){
            [[ChatTools sharedInstance] requestCall:members listener:self];
        }
    }
}

- (void)didSelect:(NSArray *)values tag:(NSInteger)tag {
    if (tag == 0) { // share contact
        if (values.count > 0) {
            NSInteger contactId = [[values objectAtIndex:0] integerValue];
            YooMessage *yooMsg = [self buildNewMessage];
            yooMsg.type = ymtContact;
            yooMsg.shared = [NSNumber numberWithInteger:contactId];
            [self send:yooMsg];
        }
    } else if (tag == 1) { // edit group
        YooGroup *group = (YooGroup *)self.recipient;
        NSArray *members = [GroupDAO listMembers:group.toJID];
        for (NSString *name in values) {
            YooUser *otherUser = [UserDAO find:name domain:YOO_DOMAIN];
            if (otherUser != nil && ![members containsObject:[otherUser toJID]]) {
                // A contact has been added
                [[ChatTools sharedInstance] addUser:[otherUser toJID] toGroup:[group toJID]];
            }
        }
        for (NSString *jid in members) {
            YooUser *otherUser = [UserDAO findByJid:jid];
            NSString *contactId = [NSString stringWithFormat:@"%ld", (long)otherUser.contactId];
            if (otherUser != nil && ![otherUser isMe] && ![values containsObject:contactId]) {
                // A contact has been removed
                [[ChatTools sharedInstance] removeUser:[otherUser toJID] fromGroup:[group toJID]];
            }
        }
        [self buildTitleView:[[UIApplication sharedApplication] statusBarOrientation]];
    } else if (tag == 2) { // forward message
        NSString *name = [values objectAtIndex:0];
        YooUser *yooUser = [UserDAO find:name domain:YOO_DOMAIN];
        self.forwarded.to = yooUser;
        self.forwarded.thread = nil;
        [[ChatTools sharedInstance] sendMessage:self.forwarded];
        
    }
 }


- (YooMessage *)buildNewMessage {
    YooMessage *yooMsg = [[YooMessage alloc] init];
    yooMsg.to = self.recipient;
    yooMsg.location = [LocationTools sharedInstance].location.coordinate;
    yooMsg.thread = self.thread;
    return yooMsg;
}





- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self buildTitleView:toInterfaceOrientation];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self update];
}


- (void)buildTitleView:(UIInterfaceOrientation)orientation {

    // setup titleview
    // Replace titleView
    int titleWidth = 0;
    
    UIView *window = self.tabBarController.view.superview;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        titleWidth = window.bounds.size.height;
    } else {
        titleWidth = window.bounds.size.width;
    }
    CGRect headerTitleSubtitleFrame = CGRectMake(80, 0, titleWidth - 160, 44);
    UIView* _headerTitleSubtitleView = [[UILabel alloc] initWithFrame:headerTitleSubtitleFrame];
    _headerTitleSubtitleView.backgroundColor = [UIColor clearColor];
    _headerTitleSubtitleView.autoresizesSubviews = YES;

    
    CGRect titleFrame = CGRectMake(0, 2, headerTitleSubtitleFrame.size.width, 24);
    UILabel *titleView = [[UILabel alloc] initWithFrame:titleFrame];
    titleView.backgroundColor = [UIColor clearColor];
    titleView.font = [UIFont boldSystemFontOfSize:18];
    titleView.textAlignment = NSTextAlignmentCenter;
    titleView.textColor = [UITools isIOS7] ? [UIColor blackColor] : [UIColor whiteColor];
    titleView.text = self.title;
    titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_headerTitleSubtitleView addSubview:titleView];
    
    // Subtitle only in portrait orientation, there is not enough space in landscape orientation
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        NSString *subtitle = nil;
        if (self.mode == cmChat) {
            if ([[ChatTools sharedInstance] isPresent:(YooUser *)self.recipient]) {
                subtitle = NSLocalizedString(@"STATUS_ONLINE", nil);
            } else {
                if (((YooUser *)self.recipient).lastonline == nil) {
                    subtitle = NSLocalizedString(@"STATUS_OFFLINE", nil);
                } else {
                    // check if the date is today
                    NSDate *lastLogDate = ((YooUser *)self.recipient).lastonline;
                    NSCalendar *cal = [NSCalendar currentCalendar];
                    NSDateComponents *components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
                    NSDate *today = [cal dateFromComponents:components];
                    components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:lastLogDate];
                    NSDate *otherDate = [cal dateFromComponents:components];
                    if ([today isEqualToDate:otherDate]) {
                        // last log was today
                        NSDateFormatter *df = [[NSDateFormatter alloc] init];
                        [df setTimeStyle:NSDateFormatterShortStyle];
                        subtitle = [NSString stringWithFormat:@"%@ %@, %@", NSLocalizedString(@"LAST_ONLINE", nil), NSLocalizedString(@"TODAY", nil), [df stringFromDate:((YooUser *)self.recipient).lastonline]];
                    } else {
                        NSDateFormatter *df = [[NSDateFormatter alloc] init];
                        [df setDateStyle:NSDateFormatterMediumStyle];
                        subtitle = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"LAST_ONLINE", nil), [df stringFromDate:((YooUser *)self.recipient).lastonline]];
                    }
                }
            }
        } else if (self.mode == cmGroup) {
            YooGroup *group = (YooGroup *)self.recipient;
            NSMutableArray *members = [NSMutableArray array];
            for (NSString *userJid in [GroupDAO listMembers:group.toJID]) {
                YooUser *user = [UserDAO findByJid:userJid];
                if (user != nil) {
                    [members addObject:user];
                }
            }
            subtitle = [self usersToString:members];
        } else if (self.mode == cmBroadcast) {
            YooBroadcast *broadcast = (YooBroadcast *)self.recipient;
            NSMutableArray *members = [NSMutableArray array];
            for (NSString *name in broadcast.names) {
                YooUser *user = [UserDAO find:name domain:YOO_DOMAIN];
                if (user != nil) {
                    [members addObject:user];
                }
            }
            subtitle = [self usersToString:members];
        }
        CGRect subtitleFrame = CGRectMake(0, 24, headerTitleSubtitleFrame.size.width, 44-26);
        UILabel *subtitleView = [[UILabel alloc] initWithFrame:subtitleFrame];
        subtitleView.backgroundColor = [UIColor clearColor];
        subtitleView.font = [UIFont boldSystemFontOfSize:12];
        subtitleView.textAlignment = NSTextAlignmentCenter;
        subtitleView.textColor = [UITools isIOS7] ? [UIColor grayColor] : [UIColor whiteColor];
        subtitleView.text = subtitle;
        subtitleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_headerTitleSubtitleView addSubview:subtitleView];
    }
    
    //_headerTitleSubtitleView.autoresizingMask = UIV;
    
    self.navigationItem.titleView = _headerTitleSubtitleView;
    
}


- (NSString *)usersToString:(NSArray *)array {
    NSMutableString *tmp = [NSMutableString string];
    for (YooUser *yooUser in array) {
        if (yooUser.isMe) continue;
        if (tmp.length > 0) {
            [tmp appendString:@", "];
        }
        [tmp appendString:yooUser.alias];
    }
    return tmp;
            
}

//- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
//{
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
//}

- (void)editGroup {
    YooGroup *group = (YooGroup *)self.recipient;
    NSString *prefix = [NSString stringWithFormat:@"%@-", [ChatTools sharedInstance].login];
    NSArray *members = [GroupDAO listMembers:group.toJID];
    NSMutableArray *selected = [NSMutableArray array];
    for (NSString *jid in members) {
        YooUser *user = [UserDAO findByJid:jid];
        if (user != nil && ![user isMe]) {
            [selected addObject:[NSString stringWithFormat:@"%ld", (long)user.contactId]];
        }
    }
    
    ContactListVC *contactVC = [[ContactListVC alloc] initWithType:[group.name hasPrefix:prefix] ? clContactMultiSelect : clContactReadonly listener:self title:[group.name hasPrefix:prefix] ? NSLocalizedString(@"EDIT_GROUP", nil) : NSLocalizedString(@"GROUP_MEMBERS", nil) selected:selected];
    contactVC.tag = 1;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVC];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)imageClick:(id)sender {
    UIButton *button = (UIButton *)sender;
    YooMessage *message = [self.messages objectAtIndex:button.tag];
    PictureVC *pictureVC = [[PictureVC alloc] initWithPictures:message.pictures];
    [self.navigationController pushViewController:pictureVC animated:YES];
}

/*
 * Call one to one
 */
-(void) didCallSendOutMessage{
    NSString *displayName = @"";
    if (self.mode == cmGroup){
        YooGroup *group = (YooGroup *)self.recipient;
        displayName = group.name;
    }else if(self.mode == cmChat){
        displayName = self.contact.fullName;
    }
    if([displayName length]>0){
        YooMessage *yooMsg = [self buildNewMessage];
        yooMsg.type = ymtCallRequest;
        yooMsg.message = [NSString stringWithFormat:@"Call %@", displayName];
        [self send:yooMsg];
    }
}

/*
 * Call one to many
 */
//- (void)didSendMessageWithConferenceNumbers:(NSMutableArray *) pConferenceNumbers{
//
//}


- (void)callPhoneNumber:(UIButton *)sender{
    UIButton *button = (UIButton *)sender;
    YooMessage *message = [self.messages objectAtIndex:button.tag];
//    NSString *phNo = @"+919876543210";
    NSString *phNo = message.conferenceNumber;
    NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",phNo]];
    
    if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
        [[UIApplication sharedApplication] openURL:phoneUrl];
    } else
    {
        UIAlertView *calert = [[UIAlertView alloc]initWithTitle:@"Alert" message:@"Call facility is not available!!!" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
        [calert show];
    }
}

- (void)sendImages:(NSArray *)images {
    YooMessage *yooMsg = [self buildNewMessage];
    NSMutableArray *pictureData = [NSMutableArray array];
    for (UIImage *image in images) {
        UIImage *resized = [ImageTools resize:image maxWidth:640];
        [pictureData addObject:UIImagePNGRepresentation(resized)];
    }
    yooMsg.pictures = pictureData;
    yooMsg.type = ymtPicture;
    [self performSelectorOnMainThread:@selector(send:) withObject:yooMsg waitUntilDone:NO];
}


- (void)didSelectImages:(NSArray *)images {
    [self performSelectorInBackground:@selector(sendImages:) withObject:images];
}


- (void)didSelect:(MKMapItem *)item {
    YooMessage *yooMsg = [self buildNewMessage];
    yooMsg.type = ymtLocation;
    yooMsg.message = [NSString stringWithFormat:@"%@\n%@", item.name, item.placemark.title];
    yooMsg.location = item.placemark.location.coordinate;
    [self send:yooMsg];
}

- (void)didRecord:(NSData *)sound duration:(NSString *)duration {
    YooMessage *yooMsg = [self buildNewMessage];
    yooMsg.type = ymtSound;
    yooMsg.sound = sound;
    yooMsg.message = duration;
    [self send:yooMsg];
}


- (void)playSound:(id)sender {
    UIButton *button = (UIButton *)sender;
    YooMessage *message = [self.messages objectAtIndex:button.tag];
    
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:message.sound error:&error];
    self.audioPlayer.volume = 1;
    self.audioPlayer.delegate = self;
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
}

- (void)viewContact {
    ContactDetailVC *detailVC = [[ContactDetailVC alloc] initWithContact:((YooUser *)self.recipient).contactId];
    detailVC.showChatButton = NO;
    // Chamroeun
    detailVC.showCallButton = NO;
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (void)longPress:(id)sender {
    UIGestureRecognizer *recognizer = (UIGestureRecognizer *)sender;
    UIView *bubble = (UIView *)recognizer.view;
    self.forwarded = [self.messages objectAtIndex:bubble.tag];
    ContactListVC *contactVC = [[ContactListVC alloc] initWithType:clContactSelect listener:self title:NSLocalizedString(@"FORWARD_MESSAGE", nil) selected:nil];
    contactVC.tag = 2;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVC];
    [self presentViewController:nav animated:YES completion:nil];
}

@end
