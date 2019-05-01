//
//  ContactManager.h
//  Yoo
//
//  Created by Arnaud on 23/08/13.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "Contact.h"
#import "ContactListener.h"

@interface ContactManager : NSObject

@property (nonatomic, retain) NSMutableArray *removed;
@property (nonatomic, retain) NSMutableArray *listeners;

+ (ContactManager *)sharedInstance;
- (void)addListener:(NSObject <ContactListener> *)listener;
- (void)removeListener:(NSObject <ContactListener> *)listener;
- (void)initAddressBook;
- (void)import;
- (Contact *)find:(NSInteger)contactId;
- (ABRecordID)createFromYoo:(Contact *)contact jid:(NSString *)jid;
- (ABRecordID)create:(Contact *)contact;
- (Contact *)findByName:(NSString *)alias;
- (void)createFakeData;
- (void)clearCache;

@end
