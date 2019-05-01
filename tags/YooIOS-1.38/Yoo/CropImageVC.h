//
//  CropImageVC.h
//  Yoo
//
//  Created by Arnaud on 04/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CropSelection.h"
#import "CropListener.h"
#import "BaseVC.h"

@interface CropImageVC : BaseVC

@property (nonatomic, retain) UIView *mainView;
@property (nonatomic, retain) UIImage *image;
@property (assign) CGRect selection;
@property (nonatomic, retain) CropSelection *cropSel;
@property (nonatomic, retain) NSMutableArray *handles;
@property (assign) CGRect imgBounds;
@property (nonatomic, retain) NSObject <CropListener> *listener;

- (id)initWithImage:(UIImage *)pImage listener:(NSObject <CropListener> *)pListener;

@end
