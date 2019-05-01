//
//  CropListener.h
//  Yoo
//
//  Created by Arnaud on 05/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CropListener <NSObject>

- (void)didCrop:(UIImage *)image;

@end
