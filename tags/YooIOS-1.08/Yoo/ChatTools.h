//
//  ChatTools.h
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPStream.h"
#import "ChatListener.h"
#import "LocationListener.h"
#import "YooMessage.h"
#import "ContactListener.h"

#import "CallingListener.h"

#define REGISTRATION_USER @"registration"
#define YOO_DOMAIN @"yoo-app.com"
#define CONFERENCE_DOMAIN @"conference.yoo-app.com"
#define MAX_USER_HISTORY 20

@interface ChatTools : NSObject<LocationListener, ContactListener>

@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, retain) NSString *countryCode;
@property (nonatomic, retain) NSString *login, *password;
@property (nonatomic, retain) NSMutableArray *listeners;
@property (nonatomic, retain) NSMutableArray *present;
@property (nonatomic, retain) NSMutableArray *tested;
@property (assign) BOOL countryReady;
@property (assign) BOOL contactsReady;
@property (nonatomic, retain) NSMutableDictionary *roomUsers;
@property (nonatomic, retain) NSMutableDictionary *roomAliases;

@property (nonatomic, retain) NSObject<CallingListener> *callingDelegate;
@property (nonatomic, retain) NSMutableDictionary *mappingConferenceNumbers;

+ (ChatTools *)sharedInstance;
- (void)login:(NSString *)pLogin password:(NSString *)pPassword;
- (void)addListener:(NSObject <ChatListener> *)listener;
- (void)removeListener:(NSObject <ChatListener> *)listener;
- (NSArray *)messagesForRecipient:(NSObject<YooRecipient> *)recipient withPicture:(BOOL)pict;
- (void)sendMessage:(YooMessage *)yooMsg;
- (BOOL)isPresent:(YooUser *)user;
- (YooUser *)checkFriend:(NSString *)name domain:(NSString *)domain;
- (NSArray *)listUsers;
- (void)registerUser:(NSString *)name phone:(NSString *)phone countryCode:(NSInteger)countryCode;
- (void)registerUser:(NSString *)phone code:(NSString *)code;
- (void)logout;
- (UInt64)stats:(BOOL)sent;
- (void)sendPresence;
- (void)setDevice:(NSString *)deviceToken;
- (void)disconnect;
- (void)markAsRead:(NSObject<YooRecipient> *)yooUser;
- (void)setNickname:(NSString *)nickame picture:(NSData *)picture;
- (NSString *)getStatus;
- (void)requestVCard:(NSString *)jid;
- (void)createGroup:(NSString *)groupName users:(NSArray *)users;
- (void)addUser:(NSString *)userJid toGroup:(NSString *)groupJid;
- (void)removeUser:(NSString *)userJid fromGroup:(NSString *)groupJid;
- (void)destroyGroup:(NSString *)groupJid;

- (void)requestCall:(NSArray *) pMembers listener:(NSObject<CallingListener> *) listener;
@end
