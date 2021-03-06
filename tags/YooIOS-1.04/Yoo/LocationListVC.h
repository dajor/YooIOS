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

@interface LocationListVC : UITableViewController<MapSearchListener, UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, retain) NSObject <LocationListListener> *listener;
@property (nonatomic, retain) NSMutableArray *locations;
@property (nonatomic, strong) UISearchDisplayController *sdc;

- (id)initWithListener:(NSObject <LocationListListener> *)pListener;

@end
