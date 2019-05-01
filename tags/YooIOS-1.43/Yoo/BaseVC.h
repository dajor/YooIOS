//
//  BaseVC.h
//  Yoo
//
//  Created by Arnaud on 06/01/2015.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#define STATUS_HEIGHT 20
#define HEADER_HEIGHT 44

@interface BaseVC : UIViewController

@property (assign) BOOL translucent;
@property (nonatomic, retain) UIView *titleView;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic, retain) UIButton *leftBtn;
@property (nonatomic, retain) UIButton *rightBtn;
@property (nonatomic, retain) UIButton *secRightBtn;
@property (nonatomic, retain) UILabel *titleLbl;
@property (nonatomic, retain) UILabel *subLbl;
@property (nonatomic, retain) UIButton *menuBtn;
@property (nonatomic, retain) UIView *separator;

- (id)initWithTitle:(NSString *)pTitle;
- (CGRect)contentRect;
- (void)updateHeader;

@end
