//
//  CountryPicklistVC.h
//  Yoo
//
//  Created by Arnaud on 02/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PicklistListener.h"
#import "BaseListVC.h"

@interface CountryPicklistVC : BaseListVC<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) NSMutableArray *sectionKeys;
@property (nonatomic, retain) NSMutableDictionary *sections;
@property (nonatomic, retain) NSMutableDictionary *countryCodeMap;
@property (nonatomic, retain) NSString *current;
@property (nonatomic, retain) NSObject <PicklistListener> *listener;

- (id)initWithCurrent:(NSString *)pCurrent listener:(NSObject <PicklistListener> *)pListener;

@end
