//
//  TriangleView.h
//  Yoo
//
//  Created by Arnaud on 14/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TriangleView : UIView

@property (assign) BOOL left;
@property (nonatomic, retain) UIColor *color;

- (id)initWithFrame:(CGRect)frame left:(BOOL)pLeft color:(UIColor *)color;

@end
