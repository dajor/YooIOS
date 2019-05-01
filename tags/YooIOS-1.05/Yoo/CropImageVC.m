//
//  CropImageVC.m
//  Yoo
//
//  Created by Arnaud on 04/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "CropImageVC.h"
#import "CropSelection.h"
#import "CropHandle.h"
#import "ImageTools.h"

@interface CropImageVC ()

@end

@implementation CropImageVC

- (id)initWithImage:(UIImage *)pImage listener:(NSObject<CropListener> *)pListener
{
    self = [super init];
    if (self) {
        self.listener = pListener;
        self.image = pImage;
        self.title = NSLocalizedString(@"CROP_IMAGE", nil);
        [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)]];
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save)]];
        if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
            self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    return self;
}

- (void)loadView {
    UIView *mainView = [[UIView alloc] init];
    [mainView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [mainView setBackgroundColor:[UIColor whiteColor]];
    [self setView:mainView];
}

- (void)setupImageView {
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
    CGSize target = CGSizeMake(self.view.frame.size.width - 32, self.view.frame.size.height - 32);
    CGSize imgRect = CGSizeMake(self.image.size.width, self.image.size.height);
    if (imgRect.width > target.width) {
        double ratio = target.width / imgRect.width;
        imgRect.width = target.width;
        imgRect.height *= ratio;
    }
    if (imgRect.height > target.height) {
        double ratio = target.height / imgRect.height;
        imgRect.width *= ratio;
        imgRect.height = target.height;
    }
    self.imgBounds = CGRectMake((self.view.frame.size.width - imgRect.width) / 2, (self.view.frame.size.height - imgRect.height) / 2, imgRect.width, imgRect.height);
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.imgBounds];
    [imgView setImage:self.image];
    imgView.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1].CGColor;
    imgView.layer.borderWidth = 2;
    [self.view addSubview:imgView];
    
    
    self.selection = imgView.frame;
    
    self.cropSel = [[CropSelection alloc] initWithFrame:self.selection];
    UIPanGestureRecognizer *recog1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragRect:)];
    [self.cropSel addGestureRecognizer:recog1];
    [self.cropSel setOpaque:NO];
    [self.cropSel setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.cropSel];
    
    self.handles = [NSMutableArray array];
    for (int j = 0; j < 2; j++) {
        for (int i = 0; i < 2; i++) {
            CGRect hRect = CGRectMake(self.selection.origin.x - 18 + i * self.selection.size.width, self.selection.origin.y - 18 + j * self.selection.size.height, 36, 36);
            CropHandle *handle = [[CropHandle alloc] initWithFrame:hRect];
            UIPanGestureRecognizer *recog2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragHandle:)];
            [handle addGestureRecognizer:recog2];
            [handle setOpaque:NO];
            [handle setBackgroundColor:[UIColor clearColor]];

            [self.view addSubview:handle];
            
            [self.handles addObject:handle];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self setupImageView];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self setupImageView];
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save {
    [self dismissViewControllerAnimated:YES completion:nil];
    double left = (self.selection.origin.x - self.imgBounds.origin.x) / self.imgBounds.size.width;
    double top = (self.selection.origin.y - self.imgBounds.origin.y) / self.imgBounds.size.height;
    double right = (self.selection.origin.x + self.selection.size.width - self.imgBounds.origin.x) / self.imgBounds.size.width;
    double bottom = (self.selection.origin.y + self.selection.size.height - self.imgBounds.origin.y) / self.imgBounds.size.height;
    
    CGRect cropRect = CGRectMake(left * self.image.size.width, top * self.image.size.height, (right - left) * self.image.size.width, (bottom - top) * self.image.size.height);
    CGImageRef imageRef = CGImageCreateWithImageInRect([self.image CGImage], cropRect);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    [self.listener didCrop:newImage];
}

CGFloat firstX, firstY;

- (void)dragHandle:(id)sender {
    UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer *)sender;
    CropHandle *handle = (CropHandle *)recognizer.view;
    NSInteger index = [self.handles indexOfObject:handle];
    CGPoint translatedPoint = [recognizer translationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        firstX = handle.center.x;
        firstY = handle.center.y;
    }
    
    translatedPoint = CGPointMake(firstX + translatedPoint.x, firstY + translatedPoint.y);
    if (translatedPoint.x < self.imgBounds.origin.x) translatedPoint.x = self.imgBounds.origin.x;
    if (translatedPoint.x > self.imgBounds.origin.x + self.imgBounds.size.width - 1) translatedPoint.x = self.imgBounds.origin.x + self.imgBounds.size.width - 1;
    if (translatedPoint.y < self.imgBounds.origin.y) translatedPoint.y = self.imgBounds.origin.y;
    if (translatedPoint.y > self.imgBounds.origin.y + self.imgBounds.size.height - 1) translatedPoint.y = self.imgBounds.origin.y + self.imgBounds.size.height - 1;
    [handle setCenter:translatedPoint];
    

    // align handle x
    CropHandle *otherX = [self.handles objectAtIndex:(index + 2) % 4];
    [otherX setCenter:CGPointMake(handle.center.x, otherX.center.y)];

    // align handle y
    CropHandle *otherY = [self.handles objectAtIndex:(index + 1)%2 + ((int)index/2) * 2];
    [otherY setCenter:CGPointMake(otherY.center.x, handle.center.y)];
    
    CropHandle *leftTop = [self.handles objectAtIndex:0];
    CropHandle *rightBottom = [self.handles objectAtIndex:3];
    int minX = MIN(leftTop.center.x, rightBottom.center.x), minY = MIN(leftTop.center.y, rightBottom.center.y);
    int maxX = MAX(leftTop.center.x, rightBottom.center.x), maxY = MAX(leftTop.center.y, rightBottom.center.y);
    [self.cropSel setFrame:CGRectMake(minX, minY, maxX - minX, maxY - minY)];
    [self.cropSel setNeedsDisplay];
    self.selection = self.cropSel.frame;
}


- (void)dragRect:(id)sender {
    UIPanGestureRecognizer *recognizer = (UIPanGestureRecognizer *)sender;
    CropSelection *cropSel = (CropSelection *)recognizer.view;
    
    CGPoint translatedPoint = [recognizer translationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        firstX = cropSel.frame.origin.x;
        firstY = cropSel.frame.origin.y;
    }
    
    translatedPoint = CGPointMake(firstX + translatedPoint.x, firstY + translatedPoint.y);
    if (translatedPoint.x < self.imgBounds.origin.x) translatedPoint.x = self.imgBounds.origin.x;
    if (translatedPoint.x > self.imgBounds.origin.x + self.imgBounds.size.width - cropSel.frame.size.width) translatedPoint.x = self.imgBounds.origin.x + self.imgBounds.size.width - cropSel.frame.size.width;
    if (translatedPoint.y < self.imgBounds.origin.y) translatedPoint.y = self.imgBounds.origin.y;
    if (translatedPoint.y > self.imgBounds.origin.y + self.imgBounds.size.height - cropSel.frame.size.height) translatedPoint.y = self.imgBounds.origin.y + self.imgBounds.size.height - cropSel.frame.size.height;
    [self.cropSel setFrame:CGRectMake(translatedPoint.x, translatedPoint.y, self.cropSel.frame.size.width, self.cropSel.frame.size.height)];
    self.selection = self.cropSel.frame;
    
    for (int j = 0; j < 2; j++) {
        for (int i = 0; i < 2; i++) {
            CropHandle *handle = [self.handles objectAtIndex:j*2 + i];
            [handle setCenter:CGPointMake(self.cropSel.frame.origin.x + i * self.cropSel.frame.size.width, self.cropSel.frame.origin.y + j * self.cropSel.frame.size.height)];
        }
    }
}

@end
