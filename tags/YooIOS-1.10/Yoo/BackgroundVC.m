//
//  BackgroundVC.m
//  Yoo
//
//  Created by Arnaud on 22/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "BackgroundVC.h"
#import "BackgroundCell.h"

@interface BackgroundVC ()

@end

@implementation BackgroundVC

- (id)init
{
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"SELECT_BACKGROUND", nil);;
    }
    return self;
}

- (void)loadView {
    CGRect rect = CGRectMake(0, 0, 200, 200);
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    UICollectionView *cv = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
    layout.minimumLineSpacing = 12;
    [cv setDataSource:self];
    [cv setDelegate:self];
    [cv setBackgroundColor:[UIColor whiteColor]];
    [cv registerClass:[BackgroundCell class] forCellWithReuseIdentifier:@"BackgroundCell"];
    [self setView:cv];
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return 9;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    BackgroundCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"BackgroundCell" forIndexPath:indexPath];
    [cell.imageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"bg%ld", (long)(indexPath.row + 1)]]];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
    [cell.imageView setClipsToBounds:YES];
    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(144, 144);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(8, 8, 8, 8);
    
}




- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"bg%ld.png", (long)(indexPath.row + 1)] forKey:@"background"];
    [self.navigationController popViewControllerAnimated:YES];
}


@end
