//
//  ActivityTools.m
//  Yoo
//
//  Created by Arnaud on 01/04/2015.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import "ActivityTools.h"
#import "UserDAO.h"
#import "ContactDAO.h"
#import "ContactManager.h"
#import "ChatTools.h"
#import "GroupDAO.h"

@implementation ActivityTools

+ (Activity *)getActivity {
    NSMutableArray *tmpSections = [NSMutableArray array];
    NSMutableDictionary *tmpRecipients = [NSMutableDictionary dictionary];
    NSMutableDictionary *tmpContactMap = [NSMutableDictionary dictionary];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyyMMdd HH:mm:ss"];
    
    // add users
    for (YooUser *yooUser in [UserDAO list]) {
        if (![yooUser isMe] && yooUser.contactId != -1) {
            Contact *contact = [ContactDAO find:yooUser.contactId];
            if (contact == nil) {
                contact = [[ContactManager sharedInstance] find:yooUser.contactId];
            }
            if (contact != nil) {
                NSArray *userMsgs = [[ChatTools sharedInstance] messagesForRecipient:yooUser withPicture:NO];
                if ([userMsgs count] > 0) {
                    YooMessage *last = [userMsgs lastObject];
                    NSString *section = [df stringFromDate:last.date];
                    if (![tmpSections containsObject:section]) {
                        [tmpSections addObject:section];
                        [tmpRecipients setObject:[NSMutableArray array] forKey:section];
                    }
                    NSMutableArray *sectionRecpt = [tmpRecipients objectForKey:section];
                    // order by last received message date
                    int i = 0;
                    for (i = 0; i < sectionRecpt.count; i++) {
                        NSArray *tuple = [sectionRecpt objectAtIndex:i];
                        YooMessage *otherLast = [tuple objectAtIndex:1];
                        if ([last.date compare:otherLast.date] == NSOrderedDescending) {
                            break;
                        }
                    }
                    [sectionRecpt insertObject:@[yooUser, last] atIndex:i];
                    [tmpContactMap setObject:contact forKey:[NSString stringWithFormat:@"%ld", (long)yooUser.contactId]];
                }
                
            }
        }
    }
    
    // add groups
    for (YooGroup *yooGroup in [GroupDAO list]) {
        NSString *section = [df stringFromDate:yooGroup.date != nil ? yooGroup.date : [NSDate date]];
        NSArray *groupMsgs = [[ChatTools sharedInstance] messagesForRecipient:yooGroup withPicture:NO];
        YooMessage *last = nil;
        if ([groupMsgs count] > 0) {
            last = [groupMsgs lastObject];
            section = [df stringFromDate:last.date];
        }
        if (![tmpSections containsObject:section]) {
            [tmpSections addObject:section];
            [tmpRecipients setObject:[NSMutableArray array] forKey:section];
        }
        NSMutableArray *sectionRecpt = [tmpRecipients objectForKey:section];
        // order by last received message date
        int i = 0;
        for (i = 0; i < sectionRecpt.count; i++) {
            NSArray *tuple = [sectionRecpt objectAtIndex:i];
            YooMessage *otherLast = [tuple objectAtIndex:1];
            if ([last.date compare:otherLast.date] == NSOrderedDescending) {
                break;
            }
        }
        if (last == nil) {
            last = [[YooMessage alloc] init];
        }
        [sectionRecpt insertObject:@[yooGroup, last] atIndex:i];
    }
    
    Activity *activity = [[Activity alloc] init];
    activity.sections = [[[tmpSections sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] reverseObjectEnumerator] allObjects];
    activity.contactMap = tmpContactMap;
    activity.yooRecipients = tmpRecipients;
    return activity;
}

@end
