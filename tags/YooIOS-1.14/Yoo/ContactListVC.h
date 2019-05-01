//
//  ContactListVC.h
//  Yoo
//
//  Created by Arnaud on 06/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocationListener.h"
#import "ChatListener.h"
#import "PicklistListener.h"
#import "ContactListener.h"
#import "BaseListVC.h"

typedef NS_ENUM(NSInteger, ContactListType) {
    clAddressBookList,
    clContactSelect,
    clAddressBookSelect,
    clContactMultiSelect,
    clContactReadonly
};


@interface ContactListVC : BaseListVC<UITableViewDataSource, UITableViewDelegate, ChatListener, UISearchDisplayDelegate, UISearchBarDelegate, ContactListener>

@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSDictionary *contactMap;
@property (nonatomic, retain) NSArray *indexes;
@property (nonatomic, retain) UISearchDisplayController *sdc;
@property (nonatomic, retain) NSString *currentFilter;
@property (assign) ContactListType type;
@property (nonatomic, retain) NSObject <PicklistListener> *listener;
@property (nonatomic, retain) NSArray *contacts;
@property (nonatomic, retain) NSMutableArray *selected;
@property (assign) NSInteger tag;
@property (nonatomic, retain) UIImage *defaultImage;

- (id)initWithType:(ContactListType)pType listener:(NSObject <PicklistListener> *)pListener title:(NSString *)pTitle selected:(NSArray *)pSelected;

@end
