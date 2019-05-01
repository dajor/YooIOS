//
//  ImageTools.h
//  Yoo
//
//  Created by Arnaud on 28/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>


#define MAX_IMAGE_SIZE 640
#define MAX_AVATAR_SIZE 144

@interface ImageTools : NSObject


+ (void)getPhoto:(UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate> *)vc edit:(BOOL)edit source:(UIImagePickerControllerSourceType)source;
+ (UIImage *)handleImageData:(NSDictionary *)info;
+ (NSData *)cropImage:(UIImage *)image;
+ (UIImage *)resize:(UIImage *)image maxWidth:(NSInteger)maxWidth;
+ (UIImage *)imageRotatedByDegrees:(UIImage*)oldImage deg:(CGFloat)degrees;
+ (UIImage *)makeRoundedImage:(UIImage *)image;

@end
