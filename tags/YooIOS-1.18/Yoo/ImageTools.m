//
//  ImageTools.m
//  Yoo
//
//  Created by Arnaud on 28/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "ImageTools.h"


@implementation ImageTools


+ (void)getPhoto:(UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate> *)vc edit:(BOOL)edit source:(UIImagePickerControllerSourceType)source {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = vc;
    picker.sourceType = source;
    [picker setAllowsEditing:edit];
    [vc presentViewController:picker animated:YES completion:nil];
}


+ (UIImage *)handleImageData:(NSDictionary *)info {
    UIImage *image = nil;
    if ([info objectForKey:UIImagePickerControllerEditedImage] != nil) {
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    } else {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    return image;

}

+ (UIImage *)resize:(UIImage *)image maxWidth:(NSInteger)maxWidth {
    if (image.size.width > maxWidth) {
        CGSize newSize = CGSizeMake(maxWidth, image.size.height * maxWidth / image.size.width);
        UIGraphicsBeginImageContext(newSize);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        image = newImage;
    }
    return image;
}

+ (NSData *)cropImage:(UIImage *)image {
    // if too big, reduce image size
    image = [ImageTools resize:image maxWidth:MAX_AVATAR_SIZE];
    // make the picture square
    if (image.size.width > image.size.height) {
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake((image.size.width - image.size.height) / 2, 0, image.size.height, image.size.height));
        image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    }
    NSLog(@"%d x %d", (int)image.size.width, (int)image.size.height);
    return UIImagePNGRepresentation(image);
}



+ (UIImage *)imageRotatedByDegrees:(UIImage*)oldImage deg:(CGFloat)degrees {
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,oldImage.size.width, oldImage.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(degrees * M_PI / 180);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, (degrees * M_PI / 180));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-oldImage.size.width / 2, -oldImage.size.height / 2, oldImage.size.width, oldImage.size.height), [oldImage CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


+ (UIImage *)makeRoundedImage:(UIImage *) image
{
    CALayer *imageLayer = [CALayer layer];
    imageLayer.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    imageLayer.contents = (id) image.CGImage;
    
    imageLayer.masksToBounds = YES;
    imageLayer.cornerRadius = MIN(image.size.height / 2, image.size.width / 2);
    
    UIGraphicsBeginImageContext(image.size);
    [imageLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return roundedImage;
}

@end
