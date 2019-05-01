//
//  ImageListListener.h
//  Yoo
//
//  Created by Arnaud on 31/03/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ImageListListener <NSObject>

- (void)didSelectImages:(NSArray *)images;

@end
