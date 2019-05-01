//
//  CountryPicklistVC.h
//  Yoo
//
//  Created by Arnaud on 02/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PicklistListener.h"

@interface CountryPicklistVC : UITableViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) NSArray *countries;
@property (nonatomic, retain) NSMutableDictionary *countryCodeMap;
@property (nonatomic, retain) NSString *current;
@property (nonatomic, retain) NSObject <PicklistListener> *listener;

- (id)initWithCurrent:(NSString *)pCurrent listener:(NSObject <PicklistListener> *)pListener;

@end
