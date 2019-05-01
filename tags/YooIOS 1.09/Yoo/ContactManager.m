//
//  ContactManager.m
//  Yoo
//
//  Created by Arnaud on 23/08/13.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "ContactManager.h"
#import "Contact.h"
#import "LabelledValue.h"
#import "ContactDAO.h"
#import "UserDAO.h"
#import "YooUser.h"

@implementation ContactManager


static ContactManager *instance = nil;

+ (ContactManager *)sharedInstance {
    if (instance == nil) {
        instance = [[ContactManager alloc] init];
    }
    return instance;
}

- (id)init {
    self = [super init];
    self.listeners = [NSMutableArray array];
    return self;
}

- (void)addListener:(NSObject <ContactListener> *)listener {
    [self.listeners addObject:listener];
}

- (void)removeListener:(NSObject<ContactListener> *)listener {
    [self.listeners removeObject:listener];
}

BOOL addressBookOK = NO;

- (void)initAddressBook {
    if (&ABAddressBookCreateWithOptions != NULL) {
        ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
        
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
            ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
                addressBookOK = granted;
            });
        }
        else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            addressBookOK = YES;
        }
        else {
            // The user has previously denied access
            addressBookOK = NO;
        }
    } else {
        addressBookOK = YES;
    }
}

- (void)setFieldAddress:(NSMutableDictionary *)item name:(NSString *)name srcName:(NSString *)srcName key:(ABPropertyID)key person:(ABRecordRef)person {
    ABMultiValueRef multiValues = ABRecordCopyValue(person, key);
    if (ABMultiValueGetCount(multiValues) > 0) {
        NSDictionary *dict = (__bridge NSDictionary *)ABMultiValueCopyValueAtIndex(multiValues, 0);
        NSString *value = [dict objectForKey:srcName];
        if ([value length] > 0) {
            [item setObject:value forKey:name];
        }
    }
}

- (NSMutableArray *)getFieldMulti:(ABPropertyID)key person:(ABRecordRef)person {
    NSMutableArray *values = [NSMutableArray array];
    ABMultiValueRef multiValues = ABRecordCopyValue(person, key);
    for (int i = 0; i < ABMultiValueGetCount(multiValues); i++) {
        CFStringRef labelStingRef = ABMultiValueCopyLabelAtIndex(multiValues, i);
        NSString *label = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(labelStingRef);
        if (key == kABPersonInstantMessageProperty) {
            NSDictionary *valueDict = (__bridge NSDictionary *)ABMultiValueCopyValueAtIndex(multiValues, i);
            if (valueDict.count == 2) {
                LabelledValue *labVal = [[LabelledValue alloc] init];
                labVal.label = label;
                labVal.value = [valueDict objectForKey:@"username"];
                [values addObject:labVal];
            }
        } else {
            NSString *value = (__bridge NSString *)ABMultiValueCopyValueAtIndex(multiValues, i);
            if ([value length] > 0) {
                LabelledValue *labVal = [[LabelledValue alloc] init];
                labVal.label = label;
                labVal.value = value;
                [values addObject:labVal];
            }
        }
    }
    return values;
}

- (NSString *)getField:(ABPropertyID)key person:(ABRecordRef)person {
    return (__bridge NSString*)ABRecordCopyValue(person, key);
}


- (void)createFakeData {
    ABAddressBookRef addressBook = NULL;
    
    CFErrorRef error = NULL;
    addressBook = ABAddressBookCreateWithOptions(NULL, &error);

    for (int i = 0; i < 1000; i++) {
        
        ABRecordRef newPerson = ABPersonCreate();
        NSString *firstname = [NSString stringWithFormat:@"%c%c%d", 'A' + (i % 26), 'A' + ((i / 26) % 26), i];
        NSLog(@"Creating %@", firstname);
        ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (__bridge CFTypeRef)(firstname), &error);
        ABRecordSetValue(newPerson, kABPersonLastNameProperty, (__bridge CFTypeRef)(firstname), &error);
        ABMutableMultiValueRef multiIM = ABMultiValueCreateMutable(kABMultiStringPropertyType);
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (NSString*)kABPersonInstantMessageServiceJabber, (NSString*)kABPersonInstantMessageServiceKey,
                                    [NSString stringWithFormat:@"%@@yoo-app.com", firstname], (NSString*)kABPersonInstantMessageUsernameKey,
                                    nil
                                    ];
        ABMultiValueAddValueAndLabel(multiIM, (__bridge CFTypeRef)(dictionary), (__bridge CFTypeRef)@"YOO", NULL);
        ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiIM,nil);
        CFRelease(multiIM);
        ABAddressBookAddRecord(addressBook, newPerson, &error);
        ABAddressBookSave(addressBook, &error);
        CFRelease(newPerson);
        if (error != NULL)
        {
            CFStringRef errorDesc = CFErrorCopyDescription(error);
            NSLog(@"Contact not saved: %@", errorDesc);
            CFRelease(errorDesc);
        }
    }
}


- (ABRecordID)create:(Contact *)contact {
    if (!addressBookOK) return -1;
    ABAddressBookRef addressBook = NULL;
    CFErrorRef error = NULL;

    addressBook = ABAddressBookCreateWithOptions(NULL, &error);

    ABRecordRef newPerson = ABPersonCreate();
    if (contact.firstName.length > 0) {
        ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (__bridge CFTypeRef)(contact.firstName), &error);
    }
    if (contact.lastName.length > 0) {
        ABRecordSetValue(newPerson, kABPersonLastNameProperty, (__bridge CFTypeRef)(contact.lastName), &error);
    }
    
    // set messaging APIs
    ABMutableMultiValueRef multiIM = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    for (LabelledValue *messaging in contact.messaging) {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (NSString*)kABPersonInstantMessageServiceJabber, (NSString*)kABPersonInstantMessageServiceKey,
                                    messaging.value, (NSString*)kABPersonInstantMessageUsernameKey,
                                    nil
                                    ];
        ABMultiValueAddValueAndLabel(multiIM, (__bridge CFTypeRef)(dictionary), (__bridge CFTypeRef)messaging.label, NULL);
    }
    ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiIM,nil);
    CFRelease(multiIM);
    
    // set emails
    ABMutableMultiValueRef multiMail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    for (LabelledValue *mail in contact.emails) {
        ABMultiValueAddValueAndLabel(multiMail, (__bridge CFTypeRef)mail.value, (__bridge CFTypeRef)mail.label, NULL);
    }
    ABRecordSetValue(newPerson, kABPersonEmailProperty, multiMail, nil);
    CFRelease(multiMail);

    // set phone numbers
    ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    for (LabelledValue *phone in contact.phones) {
        ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)phone.value, (__bridge CFTypeRef)phone.label, NULL);
    }
    ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone, nil);
    CFRelease(multiPhone);
    
    ABAddressBookAddRecord(addressBook, newPerson, &error);
    ABAddressBookSave(addressBook, &error);
    ABRecordID recordID = ABRecordGetRecordID(newPerson);
    CFRelease(newPerson);
    if (error != NULL)
    {
        CFStringRef errorDesc = CFErrorCopyDescription(error);
        NSLog(@"Contact not saved: %@", errorDesc);
        CFRelease(errorDesc);
    }
    return recordID;
}

- (ABRecordID)createFromYoo:(Contact *)contact jid:(NSString *)jid {
    if (!addressBookOK) return -1;
    ABAddressBookRef addressBook = NULL;
    CFErrorRef error = NULL;
    addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    ABRecordRef newPerson = ABPersonCreate();
    if (contact.firstName.length > 0) {
        ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (__bridge CFTypeRef)(contact.firstName), &error);
    }
    if (contact.lastName.length > 0) {
        ABRecordSetValue(newPerson, kABPersonLastNameProperty, (__bridge CFTypeRef)(contact.lastName), &error);
    }
    ABMutableMultiValueRef multiIM = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                (NSString*)kABPersonInstantMessageServiceJabber, (NSString*)kABPersonInstantMessageServiceKey,
                                jid, (NSString*)kABPersonInstantMessageUsernameKey,
                                nil
                                ];
    ABMultiValueAddValueAndLabel(multiIM, (__bridge CFTypeRef)(dictionary), (__bridge CFTypeRef)@"YOO", NULL);
    ABRecordSetValue(newPerson, kABPersonInstantMessageProperty, multiIM,nil);
    CFRelease(multiIM);
    ABAddressBookAddRecord(addressBook, newPerson, &error);
    ABAddressBookSave(addressBook, &error);
    ABRecordID recordID = ABRecordGetRecordID(newPerson);
    CFRelease(newPerson);
    if (error != NULL)
    {
        CFStringRef errorDesc = CFErrorCopyDescription(error);
        NSLog(@"Contact not saved: %@", errorDesc);
        CFRelease(errorDesc);
    }
    return recordID;
}

- (void)import {
    [self performSelectorInBackground:@selector(listInner) withObject:nil];
}

- (Contact *)findByName:(NSString *)alias {

    Contact *contact = nil;
    if (addressBookOK) {
        ABAddressBookRef addressBook = NULL;
        CFErrorRef error = NULL;
        addressBook = ABAddressBookCreateWithOptions(NULL, &error);

        CFArrayRef people = ABAddressBookCopyPeopleWithName(addressBook, (__bridge CFStringRef)(alias));
        if (CFArrayGetCount(people) > 0) {
            ABRecordRef person = CFArrayGetValueAtIndex( people, 0);
            contact = [self mapRecord:person];
            CFRelease(person);
        }
        CFRelease(addressBook);
    }
    return contact;
}

- (void)listInner {
    if (addressBookOK) {
        NSMutableArray *createdIds = [NSMutableArray array];
        ABAddressBookRef addressBook = NULL;
        CFErrorRef error = NULL;
        addressBook = ABAddressBookCreateWithOptions(NULL, &error);

        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
        CFIndex numberOfPeople = ABAddressBookGetPersonCount(addressBook);
        
        for (int i = 0; i < numberOfPeople; i++) {
            ABRecordRef person = CFArrayGetValueAtIndex( allPeople, i );
            Contact *contact = [self mapRecord:person];
            // ignore contacts with empty first name / last name
            if (contact.firstName.length > 0 || contact.lastName.length > 0) {
                if (contact.phones.count > 0 || contact.messaging.count > 0) {
                    [createdIds addObject:[NSNumber numberWithInteger:contact.contactId]];
                    [ContactDAO upsert:contact];
                }
            }
            CFRelease(person);
        }
        
        // check if some contacts have been deleted
        for (Contact *contact in [ContactDAO list]) {
            NSNumber *cid = [NSNumber numberWithInteger:contact.contactId];
            if (![createdIds containsObject:cid]) {
                [ContactDAO remove:contact.contactId];
                for (YooUser *yooUser in [UserDAO list]) {
                    if (yooUser.contactId == contact.contactId) {
                        yooUser.contactId = -1;
                        [UserDAO upsert:yooUser];
                    }
                }
            }
        }
        
        CFRelease(addressBook);
    }
    
    for (NSObject <ContactListener> *listener in self.listeners) {
        [listener performSelectorOnMainThread:@selector(contactsLoaded) withObject:nil waitUntilDone:NO];
    }

}

- (NSComparisonResult)compare:(Contact *)first with:(Contact *)second {
    NSString *firstKey = first.lastName.length > 0 ? first.lastName : first.firstName;
    NSString *secondKey = second.lastName.length > 0 ? second.lastName : second.firstName;
    NSComparisonResult compare = [firstKey.lowercaseString compare:secondKey.lowercaseString];
    if (compare == NSOrderedSame) {
        return [first.firstName.lowercaseString compare:second.firstName.lowercaseString];
    } else {
        return compare;
    }
}

- (Contact *)mapRecord:(ABRecordRef)person {
    Contact *contact = [[Contact alloc] init];
    contact.firstName = [self getField:kABPersonFirstNameProperty person:person];
    contact.lastName = [self getField:kABPersonLastNameProperty person:person];
    contact.company = [self getField:kABPersonOrganizationProperty person:person];
    contact.jobTitle = [self getField:kABPersonJobTitleProperty person:person];
    contact.phones = [self getFieldMulti:kABPersonPhoneProperty person:person];
    contact.emails = [self getFieldMulti:kABPersonEmailProperty person:person];
    contact.messaging = [self getFieldMulti:kABPersonInstantMessageProperty person:person];
//    CFDataRef imageData = ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
//    if (imageData != NULL) {
//        contact.image = [UIImage imageWithData:(__bridge NSData *)imageData];
//        CFRelease(imageData);
//    }
    //            [ContactManager setFieldAddress:row name:@"address1" srcName:@"Street" key:kABPersonAddressProperty person:person];
    //            [ContactManager setFieldAddress:row name:@"city" srcName:@"City" key:kABPersonAddressProperty person:person];
    //            [ContactManager setFieldAddress:row name:@"country" srcName:@"Country" key:kABPersonAddressProperty person:person];
    //            [ContactManager setFieldMulti:row name:@"website" key:kABPersonURLProperty person:person];
    contact.contactId = ABRecordGetRecordID(person);
    return contact;
}


static NSMutableDictionary *cache = nil;

- (Contact *)find:(NSInteger)contactId {
    Contact *contact = nil;
    if (addressBookOK) {
        if (cache == nil) {
            cache = [NSMutableDictionary dictionary];
        }
        contact = [cache objectForKey:[NSNumber numberWithInteger:contactId]];
        if (contact != nil) {
            return contact;
        }
        ABAddressBookRef addressBook = NULL;
        CFErrorRef error = NULL;
        addressBook = ABAddressBookCreateWithOptions(NULL, &error);

        ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, (ABRecordID)contactId);
        if (person != NULL) {
            contact = [self mapRecord:person];
            [cache setObject:contact forKey:[NSNumber numberWithInteger:contactId]];
            CFRelease(person);
        }
    }
    return contact;
}


- (void)clearCache {
    cache = nil;
}

@end
