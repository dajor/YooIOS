//
//  SettingsVC.h
//  Yoo
//
//  Created by Arnaud on 07/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatListener.h"
#import "FacebookListener.h"
#import "BaseListVC.h"
#import "YooUser.h"


@interface SettingsVC : BaseListVC<UIImagePickerControllerDelegate, UINavigationControllerDelegate, ChatListener, UIActionSheetDelegate, FacebookListener, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) NSArray *settings;
@property (nonatomic, retain) YooUser *me;
@property (nonatomic, retain) UIImageView *picture;
@property (nonatomic, retain) NSMutableArray *pictureOptions;
@property (nonatomic, retain) NSString *fbId;
@property (nonatomic, retain) NSData *fbPicture;

@end
