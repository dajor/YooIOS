//
//  ImageVC.h
//  Yoo
//
//  Created by Arnaud on 31/03/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageListListener.h"
#import "CropListener.h"
#import "BaseVC.h"

@interface ImageListVC : BaseVC<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, CropListener>

@property (nonatomic, retain) UIView *baseView;
@property (nonatomic, retain) NSObject<ImageListListener> *listener;
@property (nonatomic, retain) NSMutableArray *images;
@property (assign) BOOL first;
@property (nonatomic, retain) UIImageView *imgView;
@property (nonatomic, retain) UIView *thumbsView;
@property (assign) NSInteger current;
@property (nonatomic, retain) UIButton *deleteBtn;
@property (nonatomic, retain) UIButton *rotateBtn;
@property (nonatomic, retain) UIButton *cropBtn;
@property (assign) CGSize target;

- (id)initWithListener:(NSObject<ImageListListener> *)pListener;

@end
