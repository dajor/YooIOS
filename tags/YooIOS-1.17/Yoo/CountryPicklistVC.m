//
//  CountryPicklistVC.m
//  Yoo
//
//  Created by Arnaud on 02/01/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "CountryPicklistVC.h"

@implementation CountryPicklistVC


- (id)initWithCurrent:(NSString *)pCurrent listener:(NSObject<PicklistListener> *)pListener {
    self = [super initWithTitle:NSLocalizedString(@"COUNTRY_PICKLIST_TITLE", nil)];
    self.current = pCurrent;
    self.listener = pListener;
    NSArray *countryCodes = [NSLocale ISOCountryCodes];
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:[countryCodes count]];
    self.countryCodeMap = [NSMutableDictionary dictionary];
    for (NSString *countryCode in countryCodes)
    {
        NSString *country = [[NSLocale systemLocale] displayNameForKey:NSLocaleCountryCode value:countryCode];
        [tmp addObject: country];
        [self.countryCodeMap setValue:countryCode forKey:country];
    }
    self.countries = [tmp sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return self;
}

- (void)loadView {
    
    [super loadView];
    
    self.tableView = [[UITableView alloc] initWithFrame:[self contentRect] style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    int row = 0;
    for (NSString *country in self.countries) {
        if ([[self.countryCodeMap objectForKey:country] isEqualToString:self.current]) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
            break;
        }
        row++;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.countries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSString *country = [self.countries objectAtIndex:indexPath.row];
    [cell.textLabel setText:country];
    cell.accessoryType = [[self.countryCodeMap objectForKey:country] isEqualToString:self.current] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *country = [self.countries objectAtIndex:indexPath.row];
    [self.listener didSelect:@[[self.countryCodeMap objectForKey:country]] tag:0];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
