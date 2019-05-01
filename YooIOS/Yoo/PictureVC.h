//
//  PictureVC.h
//  Yoo
//
//  Created by Arnaud on 25/03/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseVC.h"

@interface PictureVC : BaseVC<UIScrollViewDelegate>

@property (nonatomic, retain) NSArray *pictures;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIPageControl *pageControl;
- (id)initWithPictures:(NSArray *)pPictures;

@end
