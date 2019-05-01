//
//  YooRecipient.h
//  Yoo
//
//  Created by Arnaud on 05/03/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YooRecipient <NSObject>

- (NSString *)toJID;
- (BOOL)isMe;

@end
