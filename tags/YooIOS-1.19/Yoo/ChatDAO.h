//
//  ChatDAO.h
//  Yoo
//
//  Created by Arnaud on 24/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YooRecipient.h"

@class YooUser;
@class YooMessage;

@interface ChatDAO : NSObject

+ (void)initTable;
+ (void)insert:(YooMessage *)yooMsg;
+ (NSArray *)list:(NSObject<YooRecipient> *)recipient withPictures:(BOOL)pict;
+ (void)markAsRead:(NSString *)jid;
+ (void)markAsSent:(NSString *)jid ident:(NSString *)ident;
+ (void)purge;
+ (NSArray *)unreadList:(NSObject<YooRecipient> *)recipient;
+ (NSInteger)unreadCount;
+ (NSInteger)unreadCountForSender:(NSObject<YooRecipient> *)recipient;
+ (YooMessage *)acknowledge:(NSString *)idMsg;
+ (void)deleteForRecipient:(NSString *)jid;
+ (NSInteger)countReceived:(YooUser *)user;
+ (NSInteger)countSent:(YooUser *)user;
+ (NSArray*) unsentList: (NSObject<YooRecipient> *)login;
+ (void)updateCall:(NSString *)jid ident:(NSString *)ident accepted:(BOOL)accepted;

@end
