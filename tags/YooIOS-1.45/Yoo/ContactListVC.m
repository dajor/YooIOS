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
    self = [super initWithTitle:pTitle];
    self.currentFilter = nil;
    
    NSString *showall = [[NSUserDefaults standardUserDefaults] objectForKey:@"showallcontact"];
    if (showall ==nil) {
        [[NSUserDefaults standardUserDefaults] setValue:@"1" forKey:@"showallcontact"];
        showall = @"1";
    }
    
    self.filtered = [showall boolValue];
    self.type = pType;
    self.listener = pListener;
    if (self.type == clContactMultiSelect) {
        self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.rightBtn setTitle:NSLocalizedString(@"DONE", nil) forState:UIControlStateNormal];
        [self.rightBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [self.rightBtn addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
        [self.rightBtn setEnabled:NO];
    }
    if (self.type == clContactSelect || self.type == clAddressBookSelect || self.type == clContactMultiSelect || self.type == clContactReadonly) {
        self.leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.leftBtn setImage:[UIImage imageNamed:@"arrow-64.png"] forState:UIControlStateNormal];
        [self.leftBtn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (self.type == clAddressBookList || self.type == clAddressBookSelect) {
        self.rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.rightBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [self.rightBtn addTarget:self action:@selector(filterContact:) forControlEvents:UIControlEventTouchUpInside];
        [self.rightBtn.titleLabel setFont:[UIFont systemFontOfSize:13]];

        if (self.filtered) {
            self.rightBtn.tag = 1;
            [self.rightBtn setTitle:@"☑ Yoo" forState:UIControlStateNormal];
            //[self.rightBtn setImage:[UIImage imageNamed:@"checkbox-on.png"] forState:UIControlStateNormal];
        }
        else
        {
            self.rightBtn.tag = 2;
            [self.rightBtn setTitle:@"☐ Yoo" forState:UIControlStateNormal];
            //[self.rightBtn setImage:[UIImage imageNamed:@"checkbox-off.png"] forState:UIControlStateNormal];
        }
    }
    
    
    self.selected = [NSMutableArray array];
    if (pSelected != nil) {
        [self.selected addObjectsFromArray:pSelected];
    }

    self.defaultImage = [ImageTools makeRoundedImage:[UIImage imageNamed:@"user-icon.png"]];
    
    [[ChatTools sharedInstance] addListener:self];
    [[ContactManager sharedInstance] addListener:self];
    [self filter:self.filtered];
    return self;
}

- (void)dealloc {
    [[ChatTools sharedInstance] removeListener:self];
    [[ContactManager sharedInstance] removeListener:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //NSInteger unread = [ChatDAO unreadCount];
    //[[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:unread > 0 ? [NSString stringWithFormat:@"%ld", (long)unread] : nil];
    if (self.type == clContactMultiSelect) {
        [self.rightBtn setEnabled:self.selected.count > 0];
    }
    if (self.type == clAddressBookList) {
        self.menuBtn.hidden = false;
    }
    else
    {
        self.menuBtn.hidden = true;
        self.separator.hidden = true;
        [self.leftBtn setFrame:CGRectMake(0, 0, 44, 44)];
    }

}

-(void) filterContact :(id)sender
{
    UIButton * btn = (UIButton*)sender;
    if (btn.tag == 1) {
        btn.tag = 2;
        self.filtered = NO;
        [self.rightBtn setTitle:@"☐ Yoo" forState:UIControlStateNormal];
        //[self.rightBtn setImage:[UIImage imageNamed:@"checkbox-off.png"] forState:UIControlStateNormal];
    }
    else
    {
        btn.tag = 1;
        self.filtered = YES;
        [self.rightBtn setTitle:@"☑ Yoo" forState:UIControlStateNormal];
        //[self.rightBtn setImage:[UIImage imageNamed:@"checkbox-on.png"] forState:UIControlStateNormal];
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:self.filtered?@"1":@"0" forKey:@"showallcontact"];
    [self filter:self.filtered];
}
- (void)filter: (BOOL) filtered{
    NSString *login = [[NSUserDefaults standardUserDefaults] stringForKey:@"login"];
    YooUser *me = [UserDAO find:login domain:YOO_DOMAIN];
    
    self.contacts = [ContactDAO list];
    NSArray *allYooUsers = [UserDAO list];
    NSDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableArray *tmpIndexes = [NSMutableArray array];
    for (Contact *contact in self.contacts) {
        
        NSMutableArray *yooUsers = [NSMutableArray array];
        for (YooUser *yooUser in allYooUsers) {
            if (yooUser.contactId == contact.contactId && ![[me contactName] isEqualToString:[yooUser contactName]]) {
                if (self.type == clContactReadonly) {
                    if (![self.selected containsObject:yooUser.name]) {
                        continue;
                    }
                }
                [yooUsers addObject:yooUser];
            }
        }
        if ([yooUsers count] > 0 || ((self.type == clAddressBookList || self.type == clAddressBookSelect) && filtered == NO)) {
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
    [super loadView];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, HEADER_HEIGHT + STATUS_HEIGHT + 44, self.view.frame.size.width, self.view.frame.size.height - HEADER_HEIGHT - STATUS_HEIGHT - 44) style:UITableViewStylePlain];
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //self.tableView.sectionIndexColor = [UITools greenColor];
    [self.view addSubview:self.tableView];
    
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, HEADER_HEIGHT + STATUS_HEIGHT, self.view.frame.size.width, 44)];
    [self.searchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
    [self.searchBar setBarTintColor:[UITools greenColor]];
    [self.searchBar setDelegate:self];
    [self.view addSubview:self.searchBar];
    
    self.sdc = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    [self.sdc setDelegate:self];
    [self.sdc setSearchResultsDataSource:self];
    [self.sdc setSearchResultsDelegate:self];
    
    
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
    BOOL present = YES;
    if ([tuple objectAtIndex:1] != [NSNull null]) {
        yooUser = [tuple objectAtIndex:1];
        present = [[ChatTools sharedInstance] isPresent:yooUser];
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
    [cell.detailTextLabel setFont:[UIFont fontWithName:@"Avenir" size:[UIFont smallSystemFontSize]]];

    // add a green circle when user is online
    for (UIView *tmp in cell.imageView.subviews) {
        [tmp removeFromSuperview];
    }
    if (present && [[tuple objectAtIndex:1] isKindOfClass:[YooUser class]]) {
        UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(31, 31, 12, 12)];
        [circle setBackgroundColor:[UITools greenColor]];
        circle.layer.cornerRadius = 6;
        [cell.imageView addSubview:circle];
    }


    UIImage *image = nil;
    if (yooUser != nil && yooUser.picture != nil) {
        image = [UIImage imageWithData:yooUser.picture];
        image = [ImageTools makeRoundedImage:image];
    } else if (contact.image != nil) {
        image = contact.image;
        image = [ImageTools makeRoundedImage:image];
    } else {
        image = self.defaultImage;
    }
    [cell.imageView setImage:image];

    
    if (self.type == clContactReadonly) {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }

    
    if (self.type == clContactMultiSelect) {
        if ([self.selected containsObject:yooUser.name]) {
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
        [self dismiss];
        [self.listener didSelect:@[yooUser.name] tag:self.tag];
    } else if (self.type == clAddressBookSelect) {
        [self dismiss];
        [self.listener didSelect:@[[NSString stringWithFormat:@"%ld", (long)contact.contactId]] tag:self.tag];
    } else if (self.type == clContactMultiSelect) {
        if ([self.selected containsObject:yooUser.name]) {
            [self.selected removeObject:yooUser.name];
            [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryNone];
        } else {
            [self.selected addObject:yooUser.name];
            [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
        [self.rightBtn setEnabled:self.selected.count > 0];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.indexes;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (void)lastOnlineChanged:(YooUser *)friend {
    // do nothing
}

- (void)friendListChanged:(NSArray *)newFriends {
    [self filter:self.filtered];
}

- (void)didReceiveMessage:(YooMessage *)message {
}

- (void)didLogin:(NSString *)error {
}

- (void)didReceiveRegistrationInfo:(NSDictionary *)info {
}

- (void)didReceiveUserFromPhone:(NSDictionary *)info {
}

- (void)handlePhoneCall:(YooMessage *)call {
}

// search bar handling
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    self.currentFilter = [searchString lowercaseString];
    [self filter:self.filtered];
	return YES;
}


- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
    self.currentFilter = nil;
    [self filter:self.filtered];
}

- (void)addressBookChanged {
    //[ContactManager list:self];
}

- (void)dismiss {
    [[ChatTools sharedInstance] removeListener:self];
    [[ContactManager sharedInstance] removeListener:self];    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)done {
    [self dismiss];
    [self.listener didSelect:self.selected tag:self.tag];
}


- (void)contactsLoaded {
    [self filter:self.filtered];
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    //[searchBar resignFirstResponder];
    [searchBar performSelector:@selector(resignFirstResponder)
                    withObject:nil
                    afterDelay:0];
}

@end
