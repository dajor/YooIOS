//
//  FacebookListener.h
//  OneXTwo
//
//  Created by Arnaud on 28/10/13.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FacebookListener <NSObject>

- (void)fbInitComplete:(BOOL)success;
- (void)fbGetUserInfo:(NSDictionary *)info;
- (void)fbGetFriends:(NSDictionary *)friends;
- (void)fbGetPicture:(NSDictionary *)picture;

@end
