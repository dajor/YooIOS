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
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"POST_LOCATION", nil);
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
        for (NSString *category in @[@"restaurant", @"coffee", @"bar", @"hotel"]) {
            [MapTools search:category listener:self];
        }
        
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        searchBar.showsCancelButton = YES;
        searchBar.delegate = self;
        self.sdc = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
        self.sdc.delegate = self;
        self.sdc.searchResultsDataSource = self;
        self.sdc.searchResultsDelegate = self;
        self.sdc.displaysSearchBarInNavigationBar = YES;
    }
    return self;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
