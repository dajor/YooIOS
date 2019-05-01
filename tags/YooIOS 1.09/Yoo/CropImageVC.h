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

@interface CropImageVC : UIViewController

@property (nonatomic, retain) UIImage *image;
@property (assign) CGRect selection;
@property (nonatomic, retain) CropSelection *cropSel;
@property (nonatomic, retain) NSMutableArray *handles;
@property (assign) CGRect imgBounds;
@property (nonatomic, retain) NSObject <CropListener> *listener;

- (id)initWithImage:(UIImage *)pImage listener:(NSObject <CropListener> *)pListener;

@end
