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
    self.sections = [NSMutableDictionary dictionary];
    self.sectionKeys = [NSMutableArray array];
    for (NSString *countryCode in countryCodes)
    {
        NSString *country = [[NSLocale systemLocale] displayNameForKey:NSLocaleCountryCode value:countryCode];
        [tmp addObject: country];

        [self.countryCodeMap setValue:countryCode forKey:country];
    }
    
    NSArray *sortedCountries = [tmp sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for (NSString *country in sortedCountries) {
        NSString *firstChar = [country substringToIndex:1];
        // remove accents
        firstChar = [[NSString alloc]
                      initWithData:
                      [firstChar dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]
                      encoding:NSASCIIStringEncoding];
        if (![self.sectionKeys containsObject:firstChar]) {
            [self.sectionKeys addObject:firstChar];
        }
        NSMutableArray *sectionItems = [self.sections objectForKey:firstChar];
        if (sectionItems == nil) {
            sectionItems = [NSMutableArray array];
            [self.sections setObject:sectionItems forKey:firstChar];
        }
        [sectionItems addObject:country];
    }
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
    int section = 0;
    for (NSString *key in self.sectionKeys) {
        NSArray *sectionItems = [self.sections objectForKey:key];
        int row = 0;
        for (NSString *country in sectionItems) {
            if ([[self.countryCodeMap objectForKey:country] isEqualToString:self.current]) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                return;
            }
            row++;
        }
        section++;
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.sectionKeys;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.sectionKeys objectAtIndex:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *key = [self.sectionKeys objectAtIndex:section];
    NSArray *sectionItems = [self.sections objectForKey:key];
    return sectionItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSString *key = [self.sectionKeys objectAtIndex:indexPath.section];
    NSArray *sectionItems = [self.sections objectForKey:key];
    NSString *country = [sectionItems objectAtIndex:indexPath.row];
    [cell.textLabel setText:country];
    cell.accessoryType = [[self.countryCodeMap objectForKey:country] isEqualToString:self.current] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *key = [self.sectionKeys objectAtIndex:indexPath.section];
    NSArray *sectionItems = [self.sections objectForKey:key];
    NSString *country = [sectionItems objectAtIndex:indexPath.row];
    [self.listener didSelect:@[[self.countryCodeMap objectForKey:country]] tag:0];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
