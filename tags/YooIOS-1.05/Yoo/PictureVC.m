//
//  PictureVC.m
//  Yoo
//
//  Created by Arnaud on 25/03/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "PictureVC.h"
#import "UITools.h"

@interface PictureVC ()

@end

@implementation PictureVC

- (id)initWithPictures:(NSArray *)pPictures
{
    self = [super init];
    if (self) {
        self.pictures = pPictures;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

- (void)loadView {
    
    UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [mainView setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, mainView.frame.size.width, mainView.frame.size.height )];
    
    [self.scrollView setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
    [self.scrollView setDelegate:self];
    [self.scrollView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    
    [self.scrollView setPagingEnabled:YES];

    [mainView addSubview:self.scrollView];
    
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(80, mainView.frame.size.height - 88, 160, 44)];
    //[self.pageControl setBackgroundColor:[UITools blueColor]];
    [self.pageControl setPageIndicatorTintColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
    [self.pageControl setCurrentPageIndicatorTintColor:[UIColor blackColor]];
    [self.pageControl setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin];
    [self.pageControl addTarget:self action:@selector(changePage) forControlEvents:UIControlEventValueChanged];
    [self.pageControl setNumberOfPages:self.pictures.count];
    [self.pageControl setCurrentPage:0];
    [self.pageControl setHidesForSinglePage:YES];
    [mainView addSubview:self.pageControl];

    [self setView:mainView];
    [self updateTitle];
    
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self refresh];
}

- (void)refresh {
    for (UIView *tmp in self.scrollView.subviews) {
        [tmp removeFromSuperview];
    }
    int i = 0;
    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width * self.pictures.count, 0)];
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    for (NSData *picData in self.pictures) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width * i, 0, self.view.frame.size.width, self.scrollView.frame.size.height)];
        [imageView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin];
        [imageView setImage:[UIImage imageWithData:picData]];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.scrollView addSubview:imageView];
        i++;
    }
}

- (void)updateTitle {
    self.title = [NSString stringWithFormat:NSLocalizedString(@"PICTURESET_TITLE", nil), (long)self.pageControl.currentPage + 1, (long)self.pictures.count];
}

- (void)viewWillAppear:(BOOL)animated {
    [self refresh];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.view.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    if (self.pageControl.currentPage != page) {
        [self.pageControl setCurrentPage:page];
        [self updateTitle];
    }
}


- (void)changePage {
    [self updateTitle];
    [self.scrollView setContentOffset:CGPointMake(self.pageControl.currentPage * self.view.frame.size.width, self.scrollView.contentOffset.y) animated:YES];
}
@end
