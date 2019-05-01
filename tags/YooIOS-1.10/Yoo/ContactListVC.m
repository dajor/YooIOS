//
//  ContactListVC.m
//  Yoo
//
//  Created by Arnaud on 06/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "ContactListVC.h"
#import "UITools.h"
#import "ContactManager.h"
#import "Contact.h"
#import "ContactDetailVC.h"
#import "LabelledValue.h"
#import "LocationTools.h"
#import "UserDAO.h"
#import "YooUser.h"
#import "ChatTools.h"
#import "ChatVC.h"
#import "ChatDAO.h"
#import "ContactDAO.h"
#import "CustomCell.h"
#import "ImageTools.h"

@implementation ContactListVC

- (id)initWithType:(ContactListType)pType listener:(NSObject <PicklistListener> *)pListener title:(NSString *)pTitle selected:(NSArray *)pSelected {
    self = [super init];
    self.currentFilter = nil;
    self.type = pType;
    self.listener = pListener;
    self.title = pTitle;
    if (self.type == clContactMultiSelect) {
        [self.navigationItem setRightBarButtonItem:
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)]];
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    if (self.type == clContactSelect || self.type == clAddressBookSelect || self.type == clContactMultiSelect) {
        [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)]];
    }
    if (self.type == clContactReadonly) {
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancel)]];
    }
    self.selected = [NSMutableArray array];
    if (pSelected != nil) {
        [self.selected addObjectsFromArray:pSelected];
    }
    [UITools setupTitleBar];
    [[ChatTools sharedInstance] addListener:self];
    [[ContactManager sharedInstance] addListener:self];
    [self filter];
    return self;
}

- (void)dealloc {
    [[ChatTools sharedInstance] removeListener:self];
    [[ContactManager sharedInstance] removeListener:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger unread = [ChatDAO unreadCount];
    [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:unread > 0 ? [NSString stringWithFormat:@"%ld", (long)unread] : nil];
    if (self.type == clContactMultiSelect) {
        [self.navigationItem.rightBarButtonItem setEnabled:self.selected.count > 0];
    }
}


- (void)filter {
    self.contacts = [ContactDAO list];
    NSArray *allYooUsers = [UserDAO list];

    
    NSDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableArray *tmpIndexes = [NSMutableArray array];
    for (Contact *contact in self.contacts) {
        NSString *contactId = [NSString stringWithFormat:@"%ld", (long)contact.contactId];
        if (self.type == clContactReadonly) {
            if (![self.selected containsObject:contactId]) {
                continue;
            }
        }
        NSMutableArray *yooUsers = [NSMutableArray array];
        for (YooUser *yooUser in allYooUsers) {
            if (yooUser.contactId == contact.contactId) {
                [yooUsers addObject:yooUser];
            }
        }
        if ([yooUsers count] > 0 || self.type == clAddressBookList || self.type == clAddressBookSelect) {
            if (self.currentFilter.length == 0
                || (contact.firstName != nil && [contact.firstName.lowercaseString rangeOfString:self.currentFilter].location != NSNotFound)
                || (contact.lastName != nil && [contact.lastName.lowercaseString rangeOfString:self.currentFilter].location != NSNotFound)) {
                unichar firstCar = '#';
                if (contact.lastName.length > 0) {
                    firstCar = [[contact.lastName uppercaseString] characterAtIndex:0];
                } else {
                    firstCar = [[contact.firstName uppercaseString] characterAtIndex:0];
                }
                if (firstCar < 'A' || firstCar > 'Z') firstCar = '#';
                NSString *key = [NSString stringWithFormat:@"%c", firstCar];
                if (![tmpIndexes containsObject:key]) {
                    [tmpIndexes addObject:key];
                }
                NSMutableArray *sectionData = [dict objectForKey:key];
                if (sectionData == nil) {
                    sectionData = [NSMutableArray array];
                    [dict setValue:sectionData forKey:key];
                }
                if (self.type == clAddressBookList || self.type == clAddressBookSelect) {
                    // address book : limit the row count for a contact to 1
                    if (yooUsers.count == 0) {
                        [yooUsers addObject:[NSNull null]];
                    }
                    if (yooUsers.count >= 2) {
                        yooUsers = [NSMutableArray arrayWithArray:[yooUsers subarrayWithRange:NSMakeRange(0, 1)]];
                    }
                }
                for (YooUser *yooUser in yooUsers) {
                    int i = 0;
                    for (i = 0; i < sectionData.count; i++) {
                        Contact *other = [[sectionData objectAtIndex:i] objectAtIndex:0];
                        if ([contact compare:other] == NSOrderedAscending) {
                            break;
                        }
                    }
                    NSArray *tuple = @[contact, yooUser];
                    [sectionData insertObject:tuple atIndex:i];
                }
            }
        }
    }
    self.indexes = [tmpIndexes sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    self.contactMap = dict;
    [self.tableView reloadData];
}

- (void)loadView {
    UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) style:UITableViewStylePlain];
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [mainView addSubview:self.tableView];
    
    
    int titleHeight = 0;
    if ([UITools isIOS7]) {
        titleHeight = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, titleHeight, 200, 44)];
    [self.searchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
    [self.searchBar setDelegate:self];
    [mainView addSubview:self.searchBar];
    
    self.sdc = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    [self.sdc setDelegate:self];
    [self.sdc setSearchResultsDataSource:self];
    [self.sdc setSearchResultsDelegate:self];
    
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top + 44, 0, self.tableView.contentInset.bottom, 0);
    
    [self setView:mainView];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    if ([UITools isIOS7]) {
        [UIView animateWithDuration:0.2 animations:^{
             self.searchBar.transform = CGAffineTransformMakeTranslation(0, -self.searchBar.frame.size.height);
        }];
    }
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    if ([UITools isIOS7]) {
        [UIView animateWithDuration:0.25 animations:^{
             self.searchBar.transform = CGAffineTransformIdentity;
        }];
    }
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[CustomCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.tag = -1;
    }
    NSString *index = [self.indexes objectAtIndex:indexPath.section];
    NSArray *sectionData = [self.contactMap objectForKey:index];
    NSArray *tuple = [sectionData objectAtIndex:indexPath.row];
    Contact *contact = [tuple objectAtIndex:0];
    YooUser *yooUser = nil;
    if ([tuple objectAtIndex:1] != [NSNull null]) {
        yooUser = [tuple objectAtIndex:1];
    }

    NSAttributedString *name = [UITools attributedName:contact];
    [[cell textLabel] setAttributedText:name];

    if (self.type == clContactSelect || self.type == clContactReadonly || self.type == clContactMultiSelect) {
        if (![yooUser.alias.lowercaseString isEqualToString:contact.fullName.lowercaseString]) {
            [cell.detailTextLabel setText:yooUser.alias];
        } else {
            [cell.detailTextLabel setText:nil];
        }
    }
    
    if (cell.tag != contact.contactId) {
        cell.tag = contact.contactId;
        UIImage *image = nil;
        if (yooUser != nil && yooUser.picture != nil) {
            image = [UIImage imageWithData:yooUser.picture];
        } else if (contact.image == nil) {
            image = [UIImage imageNamed:@"user-icon.png"];
        } else {
            [cell.imageView setImage:contact.image];
        }
        image = [ImageTools makeRoundedImage:image];
        [cell.imageView setImage:image];
    }
    cell.accessoryView = nil;
    
    if (self.type == clContactReadonly) {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    
    if (self.type == clContactMultiSelect) {
        NSString *contactId = [NSString stringWithFormat:@"%ld", (long)contact.contactId];
        if ([self.selected containsObject:contactId]) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }

    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.indexes objectAtIndex:section];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.indexes.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *index = [self.indexes objectAtIndex:section];
    NSArray *sectionData = [self.contactMap objectForKey:index];
    return sectionData.count;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *index = [self.indexes objectAtIndex:indexPath.section];
    NSArray *sectionData = [self.contactMap objectForKey:index];
    NSArray *tuple = [sectionData objectAtIndex:indexPath.row];
    Contact *contact = [tuple objectAtIndex:0];
    YooUser *yooUser = [tuple objectAtIndex:1];
    if (self.type == clAddressBookList) {
        ContactDetailVC *contactVC = [[ContactDetailVC alloc] initWithContact:contact.contactId];
        [self.navigationController pushViewController:contactVC animated:YES];
    } else if (self.type == clContactSelect) {
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.listener didSelect:@[yooUser.name] tag:self.tag];
    } else if (self.type == clAddressBookSelect) {
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.listener didSelect:@[[NSString stringWithFormat:@"%ld", (long)contact.contactId]] tag:self.tag];
    } else if (self.type == clContactMultiSelect) {
        if ([self.selected containsObject:yooUser.name]) {
            [self.selected removeObject:yooUser.name];
            [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryNone];
        } else {
            [self.selected addObject:yooUser.name];
            [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
        [self.navigationItem.rightBarButtonItem setEnabled:self.selected.count > 0];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.indexes;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (void)friendListChanged:(NSArray *)newFriends {
    [self filter];
}

- (void)didReceiveMessage:(YooMessage *)message {
}

- (void)didLogin:(NSString *)error {
}

- (void)didReceiveRegistrationInfo:(NSDictionary *)info {
}

- (void)didReceiveUserFromPhone:(NSDictionary *)info {
}

// search bar handling
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    self.currentFilter = [searchString lowercaseString];
    [self filter];
	return YES;
}


- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
    self.currentFilter = nil;
    [self filter];
}

- (void)addressBookChanged {
    //[ContactManager list:self];
}

- (void)done {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.listener didSelect:self.selected tag:self.tag];
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)contactsLoaded {
    [self filter];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    // adjust search bar view
    int titleHeight = 0;
    if ([UITools isIOS7]) {
        CGSize statusBarFrame = [UIApplication sharedApplication].statusBarFrame.size;
        CGFloat statusBarHeight = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? statusBarFrame.width : statusBarFrame.height;
        titleHeight = self.navigationController.navigationBar.frame.size.height + statusBarHeight;
    }
    self.searchBar.frame = CGRectMake(self.searchBar.frame.origin.x, titleHeight, self.searchBar.frame.size.width, self.searchBar.frame.size.height);
}

@end
