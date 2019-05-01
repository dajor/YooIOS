//
//  LocationListVC.m
//  Yoo
//
//  Created by Arnaud on 07/04/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "LocationListVC.h"
#import <MapKit/MKMapItem.h>
#import <MapKit/MKPlacemark.h>
#import "LocationTools.h"
#import "MapTools.h"
#import "MapItem.h"


@interface LocationListVC ()

@end

@implementation LocationListVC

- (id)initWithListener:(NSObject <LocationListListener> *)pListener {
    self = [super initWithTitle:NSLocalizedString(@"POST_LOCATION", nil)];
    if (self) {
        self.listener = pListener;
        self.locations = [NSMutableArray array];
        CLLocationCoordinate2D loc = [LocationTools sharedInstance].location.coordinate;
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:loc addressDictionary:nil];
        MKMapItem *mkMapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mkMapItem setName:NSLocalizedString(@"CURRENT_LOCATION", nil)];
        MapItem *mapItem = [[MapItem alloc] init];
        mapItem.category = @"current";
        mapItem.position = mkMapItem;
        [self.locations addObject:mapItem];

        [self initSearch];
        
        
        self.leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.leftBtn setImage:[UIImage imageNamed:@"arrow-64.png"] forState:UIControlStateNormal];
        [self.leftBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];

    }
    return self;
}

- (void)initSearch {
    self.locations = [NSMutableArray arrayWithArray:[self.locations subarrayWithRange:NSMakeRange(0, 1)]];
    for (NSString *category in @[@"restaurant", @"coffee", @"bar", @"hotel"]) {
        [MapTools search:category listener:self];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (void)loadView {
    
    [super loadView];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, HEADER_HEIGHT + STATUS_HEIGHT + 44, self.view.frame.size.width, self.view.frame.size.height - HEADER_HEIGHT - STATUS_HEIGHT - 44) style:UITableViewStyleGrouped];
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, HEADER_HEIGHT + STATUS_HEIGHT, self.view.frame.size.width, 44)];
    [self.searchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
    [self.searchBar setDelegate:self];
    [self.view addSubview:self.searchBar];
    
    self.sdc = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    [self.sdc setDelegate:self];
    [self.sdc setSearchResultsDataSource:self];
    [self.sdc setSearchResultsDelegate:self];


}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    return self.locations.count - 1;
}

- (void)didFind:(NSArray *)items query:(NSString *)query {
    if ([self.sdc.searchBar.text length] > 0 && ![self.sdc.searchBar.text isEqualToString:query]) return;
    for (MKMapItem *mkMapItem in items) {
        MapItem *mapItem = [[MapItem alloc] init];
        mapItem.position = mkMapItem;
        mapItem.category = query;
        [self.locations addObject:mapItem];
    }
    [self.sdc.searchResultsTableView reloadData];
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    MapItem *item = [self.locations objectAtIndex:indexPath.section == 0 ? 0 : indexPath.row + 1];
    [cell.textLabel setText:item.position.name];
    [cell.detailTextLabel setText:indexPath.section == 0 ? nil : item.position.placemark.title];
    [cell.imageView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@-64.png", item.category]]];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MapItem *item = [self.locations objectAtIndex:indexPath.section == 0 ? 0 : indexPath.row + 1];
    [self.listener didSelect:item.position];
    [self dismissViewControllerAnimated:YES completion:nil];
}


// search bar handling
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    self.locations = [NSMutableArray arrayWithArray:[self.locations subarrayWithRange:NSMakeRange(0, 1)]];
    [MapTools search:searchString listener:self];
    
	return YES;
}




- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
    [self initSearch];
}

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
