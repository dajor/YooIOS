//
//  LocationListVC.h
//  Yoo
//
//  Created by Arnaud on 07/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapSearchListener.h"
#import "LocationListListener.h"
#import "BaseListVC.h"

@interface LocationListVC : BaseListVC<UITableViewDelegate, UITableViewDataSource, MapSearchListener, UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, retain) NSObject <LocationListListener> *listener;
@property (nonatomic, retain) NSMutableArray *locations;
@property (nonatomic, strong) UISearchDisplayController *sdc;
@property (nonatomic, retain) UISearchBar *searchBar;

- (id)initWithListener:(NSObject <LocationListListener> *)pListener;

@end
