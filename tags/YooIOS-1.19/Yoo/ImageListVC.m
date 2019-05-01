//
//  ImageVC.m
//  Yoo
//
//  Created by Arnaud on 31/03/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "ImageListVC.h"
#import "ImageTools.h"
#import "UITools.h"
#import "CropImageVC.h"
#import "MBProgressHUD.h"

@interface ImageListVC ()

@end

@implementation ImageListVC

- (id)initWithListener:(NSObject<ImageListListener> *)pListener
{
    self = [super initWithTitle:nil];
    if (self) {
        self.listener = pListener;
        self.images = [NSMutableArray array];
        self.first = YES;
        self.current = -1;
        
        self.leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.leftBtn setImage:[UIImage imageNamed:@"arrow-64.png"] forState:UIControlStateNormal];
        [self.leftBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];

        self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.rightBtn setTitle:NSLocalizedString(@"CHAT_SEND", nil) forState:UIControlStateNormal];
        [self.rightBtn addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];

    }
    return self;
}


- (void)loadView {
    
    [super loadView];
    
    self.baseView = [[UIView alloc] initWithFrame:[self contentRect]];
    [self.baseView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [self.baseView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.baseView];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self buildView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];    
    [self buildView];
}


- (void)buildView {

    for (UIView *view in self.baseView.subviews) {
        [view removeFromSuperview];
    }
    
    self.target = UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) ? CGSizeMake(448, 168) : CGSizeMake(288, [[UIScreen mainScreen] bounds].size.height - 160);
    
    UIView *upperView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - self.target.width) / 2, 16, self.target.width, self.target.height)];
    [upperView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    [self.baseView addSubview:upperView];
    
    self.imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.target.width, self.target.height)];

    //[imgView setImage:[self.images objectAtIndex:0]];
    [self.imgView setContentMode:UIViewContentModeScaleAspectFit];
    [self.imgView setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1]];
    self.imgView.layer.borderWidth = 2;
    self.imgView.layer.borderColor = self.imgView.backgroundColor.CGColor;
    self.imgView.layer.cornerRadius = 4;
    [upperView addSubview:self.imgView];

    
    self.deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.deleteBtn setImage:[UIImage imageNamed:@"x-mark-48.png"] forState:UIControlStateNormal];
    [self.deleteBtn setBackgroundColor:[UITools greenColor]];
    self.deleteBtn.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    self.deleteBtn.layer.cornerRadius =  20;
    [self.deleteBtn addTarget:self action:@selector(deleteImage) forControlEvents:UIControlEventTouchUpInside];
    [upperView addSubview:self.deleteBtn];
    
    
    self.rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.rotateBtn setImage:[UIImage imageNamed:@"rotate-48.png"] forState:UIControlStateNormal];
    [self.rotateBtn setBackgroundColor:[UITools greenColor]];
    self.rotateBtn.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    self.rotateBtn.layer.cornerRadius =  20;
    [self.rotateBtn addTarget:self action:@selector(rotateImage) forControlEvents:UIControlEventTouchUpInside];
    [upperView addSubview:self.rotateBtn];
    
    
    self.cropBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cropBtn setImage:[UIImage imageNamed:@"crop-48.png"] forState:UIControlStateNormal];
    [self.cropBtn setBackgroundColor:[UITools greenColor]];
    self.cropBtn.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    self.cropBtn.layer.cornerRadius =  20;
    [self.cropBtn addTarget:self action:@selector(cropImage) forControlEvents:UIControlEventTouchUpInside];
    [upperView addSubview:self.cropBtn];
    
    
    
    self.thumbsView = [[UIView alloc] initWithFrame:CGRectMake(10, self.target.height + 32, self.view.frame.size.width - 20, 80)];
    [self.thumbsView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    [self.baseView addSubview:self.thumbsView];
    
    [self updateThumbs];
    [self updateImage];
    [self updateHeader];
}

- (void)updateImage {
        
    if (self.current >= 0 && self.current < self.images.count) {
        [self.deleteBtn setHidden:NO];
        [self.rotateBtn setHidden:NO];
        [self.cropBtn setHidden:NO];
        UIImage *image = [self.images objectAtIndex:self.current];
        [self.imgView setImage:image];
        CGRect rect;
        if (image.size.width / image.size.height >  self.target.width / self.target.height) {
            int height = 4 + (image.size.height * self.target.width / image.size.width);
            rect = CGRectMake(0, (self.target.height - height) / 2, self.target.width, height);
        } else {
            int width = 4 + (image.size.width * self.target.height / image.size.height);
            rect = CGRectMake((self.target.width - width)/2, 0, width, self.target.height);
        }
        self.imgView.frame = rect;
        self.deleteBtn.frame = CGRectMake(rect.origin.x + 4, rect.origin.y - 4, 40, 40);
        self.rotateBtn.frame = CGRectMake(rect.origin.x + rect.size.width - 44, rect.origin.y - 4, 40, 40);
        self.cropBtn.frame = CGRectMake(rect.origin.x + rect.size.width - 94, rect.origin.y - 4, 40, 40);
        self.title = [NSString stringWithFormat:NSLocalizedString(@"PICTURESET_TITLE", nil), (long)(self.current + 1), (long)self.images.count];
        self.rightBtn.enabled = YES;
    } else {
        self.imgView.frame = CGRectMake(0, 0, self.target.width, self.target.height);
        [self.deleteBtn setHidden:YES];
        [self.rotateBtn setHidden:YES];
        [self.cropBtn setHidden:YES];
        [self.imgView setImage:nil];
        self.title = nil;
        self.rightBtn.enabled = NO;
    }
    [self updateHeader];
//    CATransition *transition = [CATransition animation];
//    transition.duration = 0.2f;
//    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//    transition.type = kCATransitionFade;
    
//    [self.imgView.layer addAnimation:transition forKey:nil];

}

- (void)updateThumbs {
    for (UIView *child in self.thumbsView.subviews) {
        [child removeFromSuperview];
    }
    for (NSInteger i = 0; i < MIN(self.images.count+1, 6); i++) {
        UIImageView *thumbImg = [[UIImageView alloc] initWithFrame:CGRectMake(2 + i * 50, 2, 46, 46)];
        if (i < self.images.count) {
            [thumbImg setImage:[self.images objectAtIndex:i]];
        } else {
            [thumbImg setImage:nil];
        }
        [thumbImg setContentMode:UIViewContentModeScaleAspectFill];
        [thumbImg setClipsToBounds:YES];
        thumbImg.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        thumbImg.layer.borderWidth = (i == self.current) ? 4 : 2;
        thumbImg.layer.borderColor = (i == self.current) ? [UITools greenColor].CGColor : thumbImg.backgroundColor.CGColor;
        thumbImg.layer.cornerRadius = 4;
        [self.thumbsView addSubview:thumbImg];
        
        UIButton *thumbBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [thumbBtn setTag:i];
        [thumbBtn setFrame:thumbImg.frame];
        [thumbBtn addTarget:self action:@selector(thumbClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.thumbsView addSubview:thumbBtn];
        
        if (i == self.images.count) {
            UILabel *plusLbl = [[UILabel alloc] initWithFrame:
                                CGRectMake(0, 0, 46, 40)];
            [plusLbl setBackgroundColor:[UIColor clearColor]];
            [plusLbl setText:@"+"];
            [plusLbl setFont:[UIFont boldSystemFontOfSize:28]];
            [plusLbl setTextAlignment:NSTextAlignmentCenter];
            [thumbBtn addSubview:plusLbl];
        }
    }

    
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)send {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.listener didSelectImages:self.images];

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [ImageTools handleImageData:info];
    // if image is very very big, reduce its size, to prevent crash
    image = [ImageTools resize:image maxWidth:640];
    [self.images addObject:image];
    self.current = self.images.count - 1;
    [self updateThumbs];
    [self updateImage];
    //    [self dismissModalViewControllerAnimated:NO];
    

}


- (void)viewDidAppear:(BOOL)animated {
    if (self.first) {
        self.first = NO;
        [ImageTools getPhoto:self edit:NO source:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

- (void)thumbClick:(id)sender {
    UIButton *button = (UIButton *)sender;
    if (button.tag == self.images.count) {
        [ImageTools getPhoto:self edit:NO source:UIImagePickerControllerSourceTypePhotoLibrary];
    } else if (button.tag < self.images.count) {
        self.current = button.tag;
        [self updateThumbs];
        [self updateImage];
    }
    
}

- (void)deleteImage {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"REMOVE_IMAGE_TITLE", nil) message:NSLocalizedString(@"REMOVE_IMAGE_PROMPT", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:NSLocalizedString(@"REMOVE", nil), nil];
    [alert show];

}

- (void)rotateImage {
    UIImage *currentImg = [self.images objectAtIndex:self.current];
    UIImage *newImage = [ImageTools imageRotatedByDegrees:currentImg deg:270];
    [self.images setObject:newImage atIndexedSubscript:self.current];
    [self updateThumbs];
    [self updateImage];
}

- (void)cropImage {
    UIImage *currentImg = [self.images objectAtIndex:self.current];
    CropImageVC *cropVC = [[CropImageVC alloc] initWithImage:currentImg listener:self];
    UINavigationController *cropNav = [[UINavigationController alloc] initWithRootViewController:cropVC];
    [cropNav setNavigationBarHidden:YES];
    [self presentViewController:cropNav animated:YES completion:nil];
}

- (void)didCrop:(UIImage *)image {
    [self.images setObject:image atIndexedSubscript:self.current];
    [self updateThumbs];
    [self updateImage];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // delete image
        [self.images removeObjectAtIndex:self.current];
        while (self.current >= self.images.count && self.current >= 0) {
            self.current --;
        }
        [self updateThumbs];
        [self updateImage];
    }
}


//
// to fix the issue with the status bar that becomes black with photo library
//
//- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
//{
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
//}

@end
