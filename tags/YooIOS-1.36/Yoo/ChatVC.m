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
#import "MBProgressHUD.h"

@interface ChatVC ()

@end

@implementation ChatVC



- (id)initWithMode:(ChatMode)pMode recipient:(NSObject<YooRecipient> *)pRecipient {

    self = [super initWithTitle:nil];
    self.hidesBottomBarWhenPushed = YES;
    self.messageCount = CHAT_START_SIZE;
    self.mode = pMode;
    self.recipient = pRecipient;
    self.msgHeight = nil;
    self.thread = nil;
    self.title = nil;
    self.translucent = YES;
    self.shouldStartCall = NO;
    self.moreMessages = NO;
    self.bubbles = [NSMutableDictionary dictionary];
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    
    self.secRightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.secRightBtn setImage:[UIImage imageNamed:@"phone-48.png"] forState:UIControlStateNormal];
    [self.secRightBtn addTarget:self action:@selector(startPhoneCall) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.mode == cmGroup) {
        self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.rightBtn setImage:[UIImage imageNamed:@"group-icon-gray.png"] forState:UIControlStateNormal];
        [self.rightBtn.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [self.rightBtn setTitleColor:[UIColor colorWithWhite:0 alpha:0.7] forState:UIControlStateNormal];
        [self.rightBtn addTarget:self action:@selector(editGroup) forControlEvents:UIControlEventTouchUpInside];
    }
    if (self.mode == cmChat) {
        self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.rightBtn.imageView.layer.cornerRadius = 20;
        self.rightBtn.imageView.layer.masksToBounds = YES;
        [self.rightBtn addTarget:self action:@selector(viewContact) forControlEvents:UIControlEventTouchUpInside];
        [self updatePhoto];
        [[ChatTools sharedInstance] lastPresence:((YooUser *)self.recipient).toJID];
    }
    
    if (self.mode == cmBroadcast) {
        // delete previous broadcasts
        [ChatDAO deleteForRecipient:BROADCAST_CODE];
    }
    
    [self computeSubtitle];
    return self;
}

- (void)updatePhoto {
    UIImage *image = nil;
    if (((YooUser *)self.recipient).picture != nil) {
        image = [UIImage imageWithData:((YooUser *)self.recipient).picture];
    } else {
        image = [UIImage imageNamed:@"user-icon.png"];
    }
    [self.rightBtn setImage:image forState:UIControlStateNormal];
}

- (void)loadView {
    [super loadView];
    CGRect ctRect = [self contentRect];
    UIImageView *bgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [bgView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    NSString *bgName = [[NSUserDefaults standardUserDefaults] stringForKey:@"background"];

    [bgView setImage:[UIImage imageNamed:bgName]];
    [bgView setContentMode:UIViewContentModeScaleToFill];
    [self.view insertSubview:bgView atIndex:0];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(ctRect.origin.x, ctRect.origin.y, ctRect.size.width, ctRect.size.height - FOOTER_SIZE)];
    [self.scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self.scrollView setBackgroundColor:[UIColor clearColor]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapScroll)];
    [self.scrollView addGestureRecognizer:tap];
    [self.scrollView setDelegate:self];
    [self.view addSubview:self.scrollView];

    self.footerView = [[UIToolbar alloc] initWithFrame:CGRectMake(ctRect.origin.x, ctRect.origin.y + ctRect.size.height - FOOTER_SIZE, ctRect.size.width, FOOTER_SIZE)];
    [self.footerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];


    UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    [sendBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [sendBtn setFrame:CGRectMake(self.footerView.frame.size.width - 50, 2, 48, self.footerView.frame.size.height - 4)];
    [sendBtn setImageEdgeInsets:UIEdgeInsetsMake(4,8,4,8)];
//    [sendBtn setTitle:NSLocalizedString(@"CHAT_SEND", nil) forState:UIControlStateNormal];
    [sendBtn setImage:[UIImage imageNamed:@"send.png"] forState:UIControlStateNormal];
    [sendBtn setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [sendBtn addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:sendBtn];
    
    UIButton *attachBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [attachBtn setImageEdgeInsets:UIEdgeInsetsMake(4,8,4,8)];
    [attachBtn setFrame:CGRectMake(2, 2, 48, self.footerView.frame.size.height - 4)];
    [attachBtn setImage:[UIImage imageNamed:@"clip.png"] forState:UIControlStateNormal];
    [attachBtn setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
    [attachBtn addTarget:self action:@selector(postItem:) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:attachBtn];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(52, 6, self.footerView.frame.size.width - 104, self.footerView.frame.size.height - 12)];
    [self.textView setBackgroundColor:[UIColor whiteColor]];
    [self.textView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    //[self.textView setAutocorrectionType:UITextAutocorrectionTypeNo];
    self.textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    self.textView.font = [UIFont fontWithName:@"Avenir" size:[UIFont systemFontSize]];
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
    NSString *text = [[NSUserDefaults standardUserDefaults] stringForKey:self.recipient.toJID];
    self.placeHolder.hidden = text.length > 0;
    if (text !=  nil && text.length > 0) {
        self.textView.text = text ;
    }
  
    [self.footerView addSubview:self.textView];
    [self.view addSubview:self.footerView];
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    float scrollOffset = scrollView.contentOffset.y;
    if (scrollOffset < 44)
    {
        if (self.moreMessages) {
            CGFloat heightBefore = self.scrollView.contentSize.height;
            self.messageCount += CHAT_START_SIZE;
            [self update];
            CGFloat heightAfter = self.scrollView.contentSize.height;
            self.scrollView.contentOffset = CGPointMake(0, self.scrollView.contentOffset.y + heightAfter - heightBefore);
        }
    }
}



- (void)didTapScroll {
    [self.view endEditing:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self.rightBtn setImageEdgeInsets:UIEdgeInsetsMake(2, 2, 2, 2)];

    [self removeAllBubbles];
    [self update];
    [self scrollDown:NO];
    
    // mark all messages as read
    [[ChatTools sharedInstance] markAsRead:self.recipient];
    
    if (self.shouldStartCall) {
        self.shouldStartCall = NO; // in case the view would re-appear
        [self startPhoneCall];
    }
    [self.secRightBtn setFrame:CGRectMake(self.rightBtn.frame.origin.x -44, -4, 55, 55)];
    [self.titleLbl  setFrame:CGRectMake(70, 0, self.titleView.frame.size.width - 120 - (self.secRightBtn != nil ? 30 : 0), self.titleView.frame.size.height - (self.subtitle != nil ? 18 : 0))];
     [self.subLbl setFrame:CGRectMake(70, 24, self.titleView.frame.size.width - 120-(self.secRightBtn != nil ? 30 : 0), 18)];
    
}

- (void)viewDidLayoutSubviews {
    // commented, scrolls down when opening the attachment menu
    //[self scrollDown:NO];
}

- (void)scrollDown:(BOOL)animated {

    CGFloat y = self.scrollView.contentSize.height;
    int visibleHeight = self.scrollView.frame.size.height - self.scrollView.contentInset.top - self.scrollView.contentInset.bottom;
    if (y > visibleHeight) {
        CGPoint bottomOffset = CGPointMake(0, - self.scrollView.contentInset.top + y - visibleHeight);
        if (self.messages.count == self.messageCount && animated == YES) {
            int height = [[self.msgHeight lastObject] intValue];
            [self.scrollView setContentOffset:CGPointMake(0, bottomOffset.y - height) animated:NO];
        }
        [self.scrollView setContentOffset:bottomOffset animated:animated];
    }
}

- (void)dealloc {
    [[ChatTools sharedInstance] removeListener:self];
}

// need to clean up the images on view disappearance, to prevent memory leak
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self recursiveCleanup:self.scrollView];
    [self.audioPlayer stop];
}

- (void)recursiveCleanup:(UIView *)view {
    for (UIView *child in [view subviews]) {
        if ([child isKindOfClass:[UIActivityIndicatorView class]]) {
            [(UIActivityIndicatorView *)child stopAnimating];            
        } else {
            [self recursiveCleanup:child];
        }
        [child removeFromSuperview];
    }
}


- (UIView *)buildBubble:(YooMessage *)yooMsg constraint:(CGSize)constraintSize leftMargin:(CGFloat)leftMargin format:(NSDateFormatter *)tf {
    
    UIFont *messageFont = [UIFont fontWithName:@"Avenir" size:[UIFont systemFontSize]];
    UIFont *timeFont = [UIFont fontWithName:@"Avenir" size:10];
    
    NSInteger seconds = -[yooMsg.date timeIntervalSinceNow];

    
    CGSize size;
    UIColor *bubbleColor = [yooMsg.from isMe] ? [UIColor colorWithRed:1.0 green:1.0 blue:0.9 alpha:1.0] : [UIColor whiteColor];
    // compute message
    NSString *displayedText = [yooMsg toDisplay];
    if (yooMsg.type == ymtContact) {
        bubbleColor = [UIColor colorWithRed:0.9 green:1 blue:0.9 alpha:1.0];
    }
    if (yooMsg.type == ymtSound) {
        bubbleColor = [UIColor colorWithRed:0.95 green:1 blue:0.95 alpha:1.0];
    }
    if (yooMsg.type == ymtCallRequest) {
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
    } else {
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
    CGSize dateSize = [UITools getStringSize:dateTxt font:timeFont constraint:CGSizeMake(MAXFLOAT, MAXFLOAT)];
    dateSize = CGSizeMake(dateSize.width + 4, dateSize.height);
    if ([yooMsg.from isMe]) {
        dateSize = CGSizeMake(dateSize.width + 22, dateSize.height);
    }
    if (yooMsg.type == ymtText || yooMsg.type == ymtContact) {
        __block NSMutableString *lastLine = nil;
        __block NSInteger lineCount = 0;
        __block CGSize tmpSize = CGSizeZero, prevSize = CGSizeZero;
        __block NSMutableString *prefix = [[NSMutableString alloc] init];
        // emoji are encoded over two characters, a simple for will not work here.
        // See http://www.objc.io/issue-9/unicode.html
        [displayedText enumerateSubstringsInRange:NSMakeRange(0, [displayedText length])
                                          options:NSStringEnumerationByComposedCharacterSequences
                                       usingBlock:^(NSString *substring, NSRange substringRange,
                                                    NSRange enclosingRange, BOOL *stop) {
                                           [prefix appendString:substring];
                                           tmpSize = [UITools getStringSize:prefix font:messageFont constraint:size];
                                           if (tmpSize.height > prevSize.height) {
                                               lastLine = [[NSMutableString alloc] init];
                                               lineCount++;
                                           }
                                           [lastLine appendString:substring];
                                           prevSize = tmpSize;
                                       }];
        
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
        bubbleBottom = dateSize.height - 4;
    }
    // increase size if it's a phone call
    if (yooMsg.type == ymtCallRequest) {
        bubbleRight = 30 + BUBBLE_MARGIN;
        if (![yooMsg.to isMe]) {
            if (seconds <= CALL_MAX_DELAY && yooMsg.callStatus != csRejected && yooMsg.callStatus != csAccepted
                && yooMsg.callStatus != csCancelled) {
                bubbleBottom = 40 + BUBBLE_MARGIN;
            }
        }
    }
    
    // build the bubble containing the message
    CGFloat bx = BUBBLE_MARGIN * 2 + leftMargin;
    if ([yooMsg.from isMe]) {
        bx = self.view.frame.size.width - size.width - BUBBLE_MARGIN*4 - bubbleRight;
        
    }
    UIView *bubble = [[UIView alloc] initWithFrame:CGRectMake(bx, 0, size.width + bubbleRight + BUBBLE_MARGIN * 2, size.height + bubbleTop + bubbleBottom + BUBBLE_MARGIN * 2)];
    bubble.layer.cornerRadius = 4;
    bubble.tag = [yooMsg.yooId integerValue];
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
            [hiddenButton setTag:[yooMsg.yooId integerValue]];
            [bubble addSubview:hiddenButton];
            
            y1 += tmp.height + BUBBLE_MARGIN;
        }
        
    } else if (yooMsg.type == ymtSound) {
        self.isPaused = NO;
        UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [playBtn setFrame:CGRectMake(BUBBLE_MARGIN, BUBBLE_MARGIN + bubbleTop, 44, 44)];
        [playBtn setTag:[yooMsg.yooId integerValue]];
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
        
    }else {
    
        UILabel *msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(BUBBLE_MARGIN, BUBBLE_MARGIN + bubbleTop, size.width, size.height)];
        [msgLabel setFont:messageFont];
        [msgLabel setText:displayedText];
        [msgLabel setNumberOfLines:0];
        [msgLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [msgLabel setBackgroundColor:[UIColor clearColor]];
        [bubble addSubview:msgLabel];
        
        if(yooMsg.type == ymtContact){
            UIImage *arrow = [UIImage imageNamed:@"arrow-forward-64.png"];
            UIImageView *arrowView = [[UIImageView alloc]initWithFrame:CGRectMake(bubble.frame.size.width - 20, 2, 15, 20)];
            arrowView.image = arrow;
            [bubble addSubview:arrowView];
            
            CGSize bsize = [bubble frame].size;
            UIButton *hiddenButton = [[UIButton alloc] initWithFrame:CGRectMake(BUBBLE_MARGIN, BUBBLE_MARGIN, bsize.width, size.height)];
            [hiddenButton addTarget:self action:@selector(contactClicked:) forControlEvents:UIControlEventTouchUpInside];
            [hiddenButton setTag:[yooMsg.yooId integerValue]];
            [bubble addSubview:hiddenButton];
        }
    }
    
    if (yooMsg.type == ymtCallRequest) {
        if ((seconds > CALL_MAX_DELAY && yooMsg.callStatus != csAccepted) || yooMsg.callStatus == csRejected || yooMsg.callStatus == csCancelled) {
            UILabel *cancel = [[UILabel alloc] initWithFrame:CGRectMake(bubble.frame.size.width - BUBBLE_MARGIN - 20, BUBBLE_MARGIN, 30, 20)];
            [cancel setFont:[UIFont systemFontOfSize:24]];
            [cancel setTextColor:[UIColor redColor]];
            [cancel setText:@"\u2715"];
            [bubble addSubview:cancel];
        } else if (yooMsg.callStatus == csAccepted) {
            UILabel *accept = [[UILabel alloc] initWithFrame:CGRectMake(bubble.frame.size.width - BUBBLE_MARGIN - 20, BUBBLE_MARGIN, 40, 20)];
            [accept setFont:[UIFont systemFontOfSize:24]];
            [accept setTextColor:[UIColor colorWithRed:0 green:0.7 blue:0.1 alpha:1]];
            [accept setText:@"\u2713"];
            [bubble addSubview:accept];
        } else {
            UIActivityIndicatorView *ind = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [ind setFrame:CGRectMake(bubble.frame.size.width - BUBBLE_MARGIN - 25, BUBBLE_MARGIN, 20, 20)];
            [bubble addSubview:ind];
            [ind startAnimating];
            [self performSelector:@selector(hideIndicator:) withObject:yooMsg.yooId afterDelay:CALL_MAX_DELAY + 1 - seconds]; // add one second to avoid looping
            // cancel button
            if (![yooMsg.to isMe]) {
                UIButton *cancel = [[UIButton alloc] initWithFrame:CGRectMake(BUBBLE_MARGIN * 2, bubble.frame.size.height - BUBBLE_MARGIN - 44, bubble.frame.size.width - BUBBLE_MARGIN * 4, 36)];
                [cancel setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:0.3]];
                [cancel addTarget:self action:@selector(cancelCall:) forControlEvents:UIControlEventTouchUpInside];
                [cancel setTitle:NSLocalizedString(@"CANCEL", nil) forState:UIControlStateNormal];
                [cancel setTag:[yooMsg.yooId integerValue]];
                [bubble addSubview:cancel];
            }
        }
       }
    NSInteger tickPos = 12;
    if ([yooMsg.from isMe] && yooMsg.sent) {
        UIImageView *sentImg = [[UIImageView alloc] initWithFrame:CGRectMake(bubble.frame.size.width - tickPos, bubble.frame.size.height - 1 - dateSize.height, 10, 10)];
        [sentImg setAlpha:0.6];
        [sentImg setImage:[self getCheckImage:yooMsg]];
        [bubble addSubview:sentImg];
        tickPos += 7;
    }
    if ([yooMsg.from isMe] && yooMsg.ack) {
        UIImageView *ackImg = [[UIImageView alloc] initWithFrame:CGRectMake(bubble.frame.size.width - tickPos, bubble.frame.size.height - 1 - dateSize.height, 10, 10)];
        [ackImg setAlpha:0.6];
        [ackImg setImage:[self getCheckImage:yooMsg]];
        [bubble addSubview:ackImg];
        tickPos += 7;
    }
    if ([yooMsg.from isMe] && yooMsg.ack && yooMsg.type == ymtCallRequest && (yooMsg.callStatus == csAccepted || yooMsg.callStatus == csRejected || yooMsg.callStatus == csCancelled || yooMsg.sent)) {
        UIImageView *acceptCall = [[UIImageView alloc] initWithFrame:CGRectMake(bubble.frame.size.width - tickPos, bubble.frame.size.height - 1 - dateSize.height, 10, 10)];
        [acceptCall setAlpha:0.6];
        [acceptCall setImage:[self getCheckImage:yooMsg]];
        [bubble addSubview:acceptCall];
        tickPos += 7;
    }
    
    // add the date
    UILabel *dateLbl = [[UILabel alloc] initWithFrame:CGRectMake(bubble.frame.size.width - dateSize.width, bubble.frame.size.height - 2 - dateSize.height, dateSize.width, dateSize.height)];
    [dateLbl setTextColor:[UIColor lightGrayColor]];
    [dateLbl setBackgroundColor:[UIColor clearColor]];
    [dateLbl setFont:timeFont];
    [dateLbl setText:dateTxt];
    [bubble addSubview:dateLbl];
    
    [self.bubbles setObject:bubble forKey:yooMsg.yooId];
    return bubble;
}

-(void)contactClicked:(UIButton *)sender{
    UIButton *button = (UIButton *)sender;
    YooMessage *message = [self getMessageById:button.tag];
    ContactDetailVC *detailVC = [[ContactDetailVC alloc] initWithContact:[message.shared integerValue]];
    detailVC.showButtons = NO;
    [self.navigationController pushViewController:detailVC animated:YES];
}

-(UIImage *)getCheckImage:(YooMessage *)message{
    if(message.type == ymtCallRequest){
        if (message.callStatus  ==  csAccepted) {
            return [UIImage imageNamed:@"check-mark-64.png"];
        }
        if (message.callStatus ==  csRejected){
            return [UIImage imageNamed:@"red-check-mark-64.png"];
        }
        return [UIImage imageNamed:@"check-mark-gray-64.png"];;
    }
    if (message.ack&&message.sent&&message.readByOther)
        return [UIImage imageNamed:@"check-mark-64.png"];
    return [UIImage imageNamed:@"check-mark-gray-64.png"];;
}

- (void)hideIndicator:(NSString *)msgId {
    if (self.isViewLoaded && self.view.window) {
        [self removeBubble:msgId];
        [self update];
    }
}

- (void)update {
    //[self performSelector:@selector(processScreenUpdate) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
    //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(processScreenUpdate) object:nil];
    // clear all the existing
    //[self recursiveCleanup:self.scrollView];
    for (UIView *tmp in self.scrollView.subviews) {
        [tmp removeFromSuperview];
    }
    
    NSArray *tmpMess = [[ChatTools sharedInstance] messagesForRecipient:self.recipient withPicture:YES limit:self.messageCount + 1];
    self.moreMessages = tmpMess.count > self.messageCount;
    self.messages = [tmpMess subarrayWithRange:NSMakeRange(self.moreMessages ? 1 : 0, tmpMess.count - (self.moreMessages ? 1 : 0))];
    
    
    int y = BUBBLE_MARGIN;
    UIFont *dateFont = [UIFont fontWithName:@"Avenir" size:[UIFont smallSystemFontSize]];
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
            CGSize textSize =[msgDate sizeWithAttributes: @{NSFontAttributeName: dateFont}];
            //[msgDate sizeWithFont:dateFont];
            UILabel *dateLbl = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - textSize.width/2 - BUBBLE_MARGIN, y, textSize.width + BUBBLE_MARGIN*2, 16)];
            [dateLbl setText:msgDate];
            [dateLbl setFont:dateFont];
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
        UIView *bubble = [self.bubbles objectForKey:yooMsg.yooId];
        if (bubble == nil) {
            bubble = [self buildBubble:yooMsg constraint:constraintSize leftMargin:leftMargin format:tf];
        }
        bubble.frame = CGRectMake(bubble.frame.origin.x, y, bubble.frame.size.width, bubble.frame.size.height);
        [self.scrollView addSubview:bubble];
        
        TriangleView *triangle;
        if ([yooMsg.from isMe]) {
            triangle = [[TriangleView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - BUBBLE_MARGIN*2, y + BUBBLE_MARGIN, BUBBLE_MARGIN, BUBBLE_MARGIN) left:NO color:bubble.backgroundColor];
        } else {
            triangle = [[TriangleView alloc] initWithFrame:CGRectMake(BUBBLE_MARGIN + leftMargin, y + BUBBLE_MARGIN, BUBBLE_MARGIN, BUBBLE_MARGIN) left:YES color:bubble.backgroundColor];
        }
        [triangle setBackgroundColor:[UIColor clearColor]];
        [self.scrollView addSubview:triangle];
        
        // in groups, add user photo
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
        }
        
        y += bubble.frame.size.height + BUBBLE_MARGIN;
        
        [tmp addObject:[NSNumber numberWithInt:bubble.frame.size.height + BUBBLE_MARGIN]];
        
        i++;
    }
    
    self.msgHeight = tmp;
    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width, y)];
    
    if (self.messages.count > 0) {
        self.thread = ((YooMessage *)[self.messages lastObject]).thread;
    }

}

- (YooMessage *)getMessageById:(NSInteger)msgId {
    for (YooMessage *tmp in self.messages) {
        if (tmp.yooId.integerValue == msgId) {
            return tmp;
        }
    }
    return nil;
}

- (void)cancelCall:(UIButton *)button {
    YooMessage *message = [self getMessageById:button.tag];
    [[ChatTools sharedInstance] cancelCall:message];
    [self removeBubble:message.yooId];
    [self update];

}

- (void)removeAllBubbles {
    NSArray *keys = [self.bubbles allKeys];
    for (NSString *key in keys) {
        [self removeBubble:key];
    }
}

- (void)removeBubble:(NSString *)yooId {
    if (yooId != nil) {
        UIView *bubble = [self.bubbles objectForKey:yooId];
        [self.bubbles removeObjectForKey:yooId];
        [self recursiveCleanup:bubble];
    }
}

- (void)didReceiveMessage:(YooMessage *)message {
    // new message received from the other
    if (message.type !=ymtMessageRead && [message.from.toJID isEqualToString:self.recipient.toJID]) {
        if (self.isViewLoaded && self.view.window) {
            [[ChatTools sharedInstance] markAsRead:self.recipient];
        }
        self.messageCount = CHAT_START_SIZE;
        [self removeBubble:message.yooId];
        [self update];
        [self scrollDown:YES];
    }
    // ack message
    if ([message.from isMe]) {
        [self removeBubble:message.yooId];
        [self update];
    }
}

- (void)lastOnlineChanged:(YooUser *)friend {
    if (friend.contactId == self.contact.contactId) {
        self.recipient = [UserDAO find:friend.name domain:YOO_DOMAIN]; // re-read the user so we have the last online date
        [self computeSubtitle];
        [self updateHeader];
    }
}

- (void)friendListChanged:(NSArray *)newFriends {
    if (self.mode == cmGroup) {
        YooGroup *group = (YooGroup *)self.recipient;
        if ([GroupDAO find:group.name] == nil) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        for (YooUser *user in newFriends) {
            if ([user.toJID isEqualToString:self.recipient.toJID]) {
                self.recipient = user;
                [self computeSubtitle];
                [self updateHeader];
                [self updatePhoto];
            }
        }
    }
}

- (void)didLogin:(NSString *)error {
}

- (NSInteger)computeKeyboardHeight:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        if ([UITools isIOS8]) return kbSize.height;
        else return kbSize.width; // use height on iOS8, width on iOS7
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
    [self animateTextField:0 duration:0.1];
}

- (void)textViewDidChange:(UITextView *)textView {
    [self.placeHolder setHidden:textView.text.length > 0];

    CGSize size = [textView sizeThatFits:textView.frame.size];
    CGFloat height = size.height;
    if (height < 32) height = 32;
    if (height > 100) height = 100;
    if (self.footerView.frame.size.height != height + 12) {
        [self.footerView setFrame:CGRectMake(self.footerView.frame.origin.x, self.footerView.frame.origin.y + self.footerView.frame.size.height - height - 12, self.footerView.frame.size.width, height + 12)];
    }
    
    NSString *version = [[UIDevice currentDevice] systemVersion];
    if ([version compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending
        && [version compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) {
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
}


- (void)animateTextField:(NSInteger)offset duration:(CGFloat)duration
{
    self.footerView.frame = CGRectMake(0, self.view.frame.size.height - self.footerView.frame.size.height + offset, self.footerView.frame.size.width, self.footerView.frame.size.height);
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, - offset, 0);
    self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset;
    
    [self scrollDown:NO];
}

- (void)sendMessage {
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:self.recipient.toJID];
    NSString *trimmed = [self.textView.text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length > 0) {
        [self.textView setText:@""];
        [self.placeHolder setHidden:NO];
        [self textViewDidChange:self.textView];
        YooMessage *yooMsg = [self buildNewMessage];
        yooMsg.message = trimmed;
        [self send:yooMsg];
    }
}

- (void)send:(YooMessage *)yooMsg {
    if (self.mode == cmBroadcast) {
        [[ChatTools sharedInstance] sendMessage:yooMsg];
        YooBroadcast *broadcast = (YooBroadcast *)self.recipient;
        for (NSString *name in broadcast.names) {
            YooUser *yooUser = [UserDAO find:name domain:YOO_DOMAIN];
            yooMsg.to = yooUser;
            yooMsg.yooId = nil;
            yooMsg.ident = nil;
            [[ChatTools sharedInstance] sendMessage:yooMsg];
        }
    } else {
        [[ChatTools sharedInstance] sendMessage:yooMsg];
    }
    self.messageCount = CHAT_START_SIZE;
    [self removeBubble:yooMsg.yooId];
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
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"POST_ITEM", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"POST_PICTURES", nil), NSLocalizedString(@"POST_LOCATION", nil), NSLocalizedString(@"POST_CONTACT", nil), NSLocalizedString(@"POST_VOICE", nil), nil];
    
    [sheet showFromRect:button.frame inView:self.view animated:YES];

}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { // picture
        ImageListVC *imageVC = [[ImageListVC alloc] initWithListener:self];
        UINavigationController *imageNav = [[UINavigationController alloc] initWithRootViewController:imageVC];
        [imageNav setNavigationBarHidden:YES];
        [self presentViewController:imageNav animated:YES completion:nil];
    } else if (buttonIndex == 1) { // location
        LocationListVC *locVC = [[LocationListVC alloc] initWithListener:self];
        UINavigationController *locNav = [[UINavigationController alloc] initWithRootViewController:locVC];
        [locNav setNavigationBarHidden:YES];
        [self presentViewController:locNav animated:YES completion:nil];
    } else if (buttonIndex == 2) { // contact
        ContactListVC *contactVC = [[ContactListVC alloc] initWithType:clAddressBookSelect listener:self title:NSLocalizedString(@"SEND_CONTACT", nil) selected:nil];
        contactVC.tag = 0;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVC];
        [nav setNavigationBarHidden:YES];
        [self presentViewController:nav animated:YES completion:nil];
    } else if (buttonIndex == 3) {
        RecordSoundVC *recordVC = [[RecordSoundVC alloc] initWithListener:self];
        UINavigationController *recordNav = [[UINavigationController alloc] initWithRootViewController:recordVC];
        [recordNav setNavigationBarHidden:YES];
        [self presentViewController:recordNav animated:YES completion:nil];
    }
//    else if (buttonIndex == 4){
//        // Button Call
//        [self startPhoneCall];
//
//    }
}

- (void)startPhoneCall {
    // check there is not already a call running
    for (YooMessage *msg in self.messages) {
        if (msg.type == ymtCallRequest && msg.callStatus == csNone && -[msg.date timeIntervalSinceNow] < CALL_MAX_DELAY) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"TWO_CALLS", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
    }

    [[ChatTools sharedInstance] requestCall:self.recipient];

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
            if (otherUser != nil && ![otherUser isMe] && ![values containsObject:otherUser.name]) {
                // A contact has been removed
                [[ChatTools sharedInstance] removeUser:[otherUser toJID] fromGroup:[group toJID]];
            }
        }
        [self computeSubtitle];
        [self updateHeader];
    } else if (tag == 2) { // forward message
        NSString *name = [values objectAtIndex:0];
        YooUser *yooUser = [UserDAO find:name domain:YOO_DOMAIN];
        self.forwarded.yooId = nil; // to create new message in DB
        self.forwarded.ident = nil;
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

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self removeAllBubbles];
    [self update];
}


- (void)computeSubtitle {
    if (self.mode == cmChat) {
        if ([[ChatTools sharedInstance] isPresent:(YooUser *)self.recipient]) {
            self.subtitle = NSLocalizedString(@"STATUS_ONLINE", nil);
        } else {
            if ([[ChatTools sharedInstance] isInvisible:(YooUser *)self.recipient]) {
                self.subtitle = @"";
            }else if (((YooUser *)self.recipient).lastonline == nil) {
                self.subtitle = NSLocalizedString(@"STATUS_OFFLINE", nil);
            } else {
                self.subtitle = [UITools lastOnlineDisplay:(YooUser *)self.recipient];
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
        self.subtitle = [self usersToString:members];
    } else if (self.mode == cmBroadcast) {
        YooBroadcast *broadcast = (YooBroadcast *)self.recipient;
        NSMutableArray *members = [NSMutableArray array];
        for (NSString *name in broadcast.names) {
            YooUser *user = [UserDAO find:name domain:YOO_DOMAIN];
            if (user != nil) {
                [members addObject:user];
            }
        }
        self.subtitle = [self usersToString:members];
    }
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

- (void)editGroup {
    YooGroup *group = (YooGroup *)self.recipient;
    NSString *prefix = [NSString stringWithFormat:@"%@-", [ChatTools sharedInstance].login];
    NSArray *members = [GroupDAO listMembers:group.toJID];
    NSMutableArray *selected = [NSMutableArray array];
    for (NSString *jid in members) {
        YooUser *user = [UserDAO findByJid:jid];
        if (user != nil && ![user isMe]) {
            [selected addObject:user.name];
        }
    }
    
    ContactListVC *contactVC = [[ContactListVC alloc] initWithType:[group.name hasPrefix:prefix] ? clContactMultiSelect : clContactReadonly listener:self title:[group.name hasPrefix:prefix] ? NSLocalizedString(@"EDIT_GROUP", nil) : NSLocalizedString(@"GROUP_MEMBERS", nil) selected:selected];
    contactVC.tag = 1;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVC];
    [nav setNavigationBarHidden:YES];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)imageClick:(id)sender {
    UIButton *button = (UIButton *)sender;
    YooMessage *message = [self getMessageById:button.tag];
    PictureVC *pictureVC = [[PictureVC alloc] initWithPictures:message.pictures];
    [self.navigationController pushViewController:pictureVC animated:YES];
}

/*
 * Call
 */
- (void)handlePhoneCall:(YooMessage *)call {
    [self removeAllBubbles];
    [self update];
    if (call.type == ymtCallRequest) [self scrollDown:YES];
}


- (void)callPhoneNumber:(UIButton *)sender {
    UIButton *button = (UIButton *)sender;
    YooMessage *message = [self getMessageById:button.tag];
    NSString *phNo = message.conferenceNumber;
    NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",phNo]];
    
    if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
        [[UIApplication sharedApplication] openURL:phoneUrl];
    } else
    {
        UIAlertView *calert = [[UIAlertView alloc]initWithTitle:@"Alert" message:@"Call facility is not available." delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
        [calert show];
    }
}

- (void)sendImages:(NSArray *)images {
    YooMessage *yooMsg = [self buildNewMessage];
    NSMutableArray *pictureData = [NSMutableArray array];
    for (UIImage *image in images) {
        UIImage *resized = [ImageTools resize:image maxWidth:640];
        [pictureData addObject:UIImageJPEGRepresentation(resized, 0.7)]; // use JPEG to save space
        //[pictureData addObject:UIImagePNGRepresentation(resized)];
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
    YooMessage *message = [self getMessageById:button.tag];
    
    NSError *error;
    if (!self.isPaused) {
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:message.sound error:&error];
        self.audioPlayer.volume = 1;
        self.audioPlayer.delegate = self;
        [self.audioPlayer prepareToPlay];
        if (self.curTime >0.0f) {
            if (self.oldMessage !=nil && ![message.yooId isEqualToString:self.oldMessage.yooId])
                [self.audioPlayer setCurrentTime:0.0f];
            else
                [self.audioPlayer setCurrentTime:self.curTime];
        }
        [self.audioPlayer play];
        self.isPaused = YES;
        self.oldMessage= message;
    } else {
        self.curTime = self.audioPlayer.currentTime ;
        [self.audioPlayer pause];
        self.isPaused = NO;
        //NSLog(@"pause: %f",self.curTime);
    }
    
}

- (void)viewContact {
    ContactDetailVC *detailVC = [[ContactDetailVC alloc] initWithContact:((YooUser *)self.recipient).contactId];
    detailVC.showButtons = NO;
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (void)longPress:(id)sender {
    UIGestureRecognizer *recognizer = (UIGestureRecognizer *)sender;
    UIView *bubble = (UIView *)recognizer.view;
    self.forwarded = [self getMessageById:bubble.tag];
    if (self.forwarded.type == ymtCallRequest) return; // calls cannot be forwarded
    ContactListVC *contactVC = [[ContactListVC alloc] initWithType:clContactSelect listener:self title:NSLocalizedString(@"FORWARD_MESSAGE", nil) selected:nil];
    contactVC.tag = 2;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:contactVC];
    [nav setNavigationBarHidden:YES];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [[NSUserDefaults standardUserDefaults] setObject:textView.text forKey:self.recipient.toJID];
    
    [textView performSelector:@selector(resignFirstResponder)
                    withObject:nil
                    afterDelay:0];
}

@end
