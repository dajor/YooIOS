//
//  MenuVC.m
//  Yoo
//
//  Created by Vanroth on 2/17/15.
//  Copyright (c) 2015 Fellow Consulting. All rights reserved.
//

#import "MenuVC.h"
#import "IIViewDeckController.h"
#import "UITools.h"
#import "ContactListVC.h"
#import "ChatListVC.h"
#import "SettingsVC.h"  
#import "ChatDAO.h"

@interface MenuVC ()

@end

@implementation MenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (id)init
{
    self = [super init];
    if (self) {
        self.options = [NSArray arrayWithObjects:@"CHAT_LIST", @"CONTACT_LIST",@"SETTINGS", nil];
        self.icons = [NSArray arrayWithObjects:@"chat-32.png", @"contacts-32.png",@"settings-32.png", nil];
    }
    
    return self;
}

-(void) loadView
{
    UIView *mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 400)];
    [mainView setBackgroundColor:[UITools menuBackgroundColor]];//[UIColor colorWithRed:96/255 green:96/255 blue:96/255 alpha:1]];
    
    headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    [headerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    headerView.backgroundColor = [UITools menuBackgroundColor];//[UIColor colorWithRed:0.30 green:0.38 blue:0.13 alpha:1];
    [mainView addSubview:headerView];
    
    //UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tab_chat.png"]];
    //[logo setFrame:CGRectMake(7, 2, 190, 77)];
    //[headerView addSubview:logo];
    
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, 320, 324)];
    [self.tableView setBackgroundColor:[UITools menuBackgroundColor]];
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [mainView addSubview:self.tableView];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    selectedIndex = indexPath;
    [self.tableView selectRowAtIndexPath:indexPath animated:YES  scrollPosition:UITableViewScrollPositionBottom];
    
    [self setView:mainView];

}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:selectedIndex animated:YES  scrollPosition:UITableViewScrollPositionBottom];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.options count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 49;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"MenuCell1";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        UIView *bg = [[UIView alloc]init];
        [bg setBackgroundColor: [UITools greenColor]];//[UIColor colorWithRed:0.30 green:0.38 blue:0.13 alpha:1]];
        cell.selectedBackgroundView = bg;
    }
    
    cell.backgroundColor = [UIColor clearColor];
    NSString *item = [self.options objectAtIndex:indexPath.row];
    UIFont* font = [UIFont fontWithName:@"Avenir" size:18];
    cell.textLabel.font = font;
    if (![UITools isIOS7]) {
        cell.textLabel.backgroundColor = [UITools menuBackgroundColor]; // fixes a display bug on iOS6
    }
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.text = NSLocalizedString(item, nil);
    cell.imageView.image = [UIImage imageNamed:[self.icons objectAtIndex:indexPath.row]];
    //cell.imageView.frame = CGRectInset(cell.imageView.frame, -32, -32);
    // Clear contentview before adding stuff ! because cells are reused
    for (UIView *tmpView in cell.contentView.subviews) {
        [tmpView removeFromSuperview];
    }

    if ([item isEqualToString:@"CHAT_LIST"]) {
        NSInteger unread = [ChatDAO unreadCount];
        if(unread>0)
        {
            NSString *unreadText = [NSString stringWithFormat:@"%ld", (long)unread];
            UIFont* font2 = [UIFont fontWithName:@"Avenir" size:14];
            UILabel *unReadlbl = [[UILabel alloc] initWithFrame:CGRectMake(224, 17, 22, 22)];
            [unReadlbl.layer setCornerRadius:11];
            [unReadlbl setTextAlignment:NSTextAlignmentCenter];
            [unReadlbl setText:unreadText];
            [unReadlbl setTextColor:[UIColor whiteColor]];
            [unReadlbl setFont:font2];
            [unReadlbl sizeToFit];
            
            CGRect rect = [unReadlbl bounds];
            rect.size.width += 10;
            rect.size.height = 22;
            if (rect.size.width<22)rect.size.width = 22;
            rect.origin.y = 17;
            rect.origin.x = 270-rect.size.width;
            unReadlbl.frame = rect;
            
            [unReadlbl setClipsToBounds:YES];
            [unReadlbl setBackgroundColor:[UIColor redColor]];
            [cell.contentView addSubview:unReadlbl];
        }
    }
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedIndex = indexPath;
    //[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *option = [self.options objectAtIndex:indexPath.row];
    UIViewController *newVC = nil;
    if ([option isEqualToString:@"CHAT_LIST"]) {
        newVC = [[ChatListVC alloc] init];
    } else if ([option isEqualToString:@"CONTACT_LIST"]) {
         newVC = [[ContactListVC alloc] initWithType:clAddressBookList listener:nil title:NSLocalizedString(@"CONTACT_LIST", nil) selected:nil];
    } else if ([option isEqualToString:@"SETTINGS"]) {
        newVC = [[SettingsVC alloc] init];
    }
    [self.viewDeckController toggleLeftView];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newVC];
    [navController setNavigationBarHidden:YES];
    [self.viewDeckController setCenterController:navController];
}

@end
