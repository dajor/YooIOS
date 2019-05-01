//
//  AppDelegate.m
//  Yoo
//
//  Created by Arnaud on 13/12/2013.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "AppDelegate.h"
#import "ChatListVC.h"
#import "DDTTYLogger.h"
#import "ChatTools.h"
#import "RegisterVC.h"
#import "ChatDAO.h"
#import "GroupDAO.h"
#import "Database.h"
#import "UserDAO.h"
#import "LocationTools.h"
#import "ContactListVC.h"
#import "ContactManager.h"
#import "SettingsVC.h"
#import "ContactDAO.h"
#import "MapTools.h"
#import "UITools.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    
    //[TestFlight takeOff:@"88278371-78b9-4812-a82f-c09a526f491d"];
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[Database getInstance] initDatabase];
    [ChatDAO initTable];
    [UserDAO initTable];
    [ContactDAO initTable];
    [GroupDAO initTable];
    
    [LocationTools sharedInstance]; // init location support
    [[ContactManager sharedInstance] initAddressBook]; // init address book tools
    
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Avenir" size:11.0f], NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    ContactListVC *contactVC = [[ContactListVC alloc] initWithType:clAddressBookList listener:nil title:NSLocalizedString(@"CONTACT_LIST", nil) selected:nil];
    UINavigationController *contactNav = [[UINavigationController alloc] initWithRootViewController:contactVC];
    [contactNav setNavigationBarHidden:YES];
    [contactNav setTabBarItem:[[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"CONTACT_LIST", nil) image:[UIImage imageNamed:@"tab_contact.png"] tag:0]];
    
    ChatListVC *chatVC = [[ChatListVC alloc] init];
    UINavigationController *chatNav = [[UINavigationController alloc] initWithRootViewController:chatVC];
    [chatNav setNavigationBarHidden:YES];
    [chatNav setTabBarItem:[[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"CHAT_LIST", nil) image:[UIImage imageNamed:@"tab_chat.png"] tag:1]];

    SettingsVC *settingsVC = [[SettingsVC alloc] init];
    UINavigationController *settingsNav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    [settingsNav setNavigationBarHidden:YES];
    [settingsNav setTabBarItem:[[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"SETTINGS", nil) image:[UIImage imageNamed:@"tab_settings.png"] tag:2]];
    
    UITabBarController *tabBar = [[UITabBarController alloc] init];
    [tabBar.tabBar setTranslucent:NO];
    [tabBar.tabBar setTintColor:[UITools greenColor]];
    [tabBar setViewControllers:[NSArray arrayWithObjects:contactNav, chatNav, settingsNav, nil]];
    
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window setTintColor:[UITools greenColor]];
    self.window.rootViewController = tabBar;
    [self.window makeKeyAndVisible];
    
    
    

    if ([userDefaults stringForKey:@"background"].length == 0) {
        [userDefaults setObject:@"bg1.png" forKey:@"background"];
    }
   
//    [userDefaults setObject:@"arnaud1" forKey:@"login"];
//    [userDefaults setObject:@"b4jv4019mz" forKey:@"password"];
//    [userDefaults setObject:@"Arnaud Marguerat" forKey:@"nickname"];
//    [userDefaults setObject:@"KH" forKey:@"countryCode"];
    
//    [userDefaults setObject:@"dajor" forKey:@"login"];
//    [userDefaults setObject:@"1qklvrks5o" forKey:@"password"];
//    [userDefaults setObject:@"Daniel Jordan" forKey:@"nickname"];
//    [userDefaults setObject:@"DE" forKey:@"countryCode"];
    
    NSString *login = [userDefaults stringForKey:@"login"];
    NSString *password = [userDefaults stringForKey:@"password"];

    if (login.length == 0 || password.length == 0) {
        RegisterVC *registerVC = [[RegisterVC alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:registerVC];
        [nav setNavigationBarHidden:YES];
        [contactNav presentViewController:nav animated:NO completion:nil];
    } else {
        [[ChatTools sharedInstance] login:login password:password];
    }

    
    // Let the device know we want to receive push notifications
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
#ifdef __IPHONE_8_0
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
#endif
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
    

    
    NSInteger unread = [ChatDAO unreadCount];
    
    
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: unread];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    [[ContactManager sharedInstance] import];
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    ABAddressBookRegisterExternalChangeCallback(addressBook, MyAddressBookExternalChangeCallback, (__bridge void *)self);

    
    
    return YES;
}

void MyAddressBookExternalChangeCallback (ABAddressBookRef notifyAddressBook, CFDictionaryRef info, void *context)
{
    [[ContactManager sharedInstance] import];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    NSInteger unread = [ChatDAO unreadCount];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: unread];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *login = [userDefaults stringForKey:@"login"];
    NSString *password = [userDefaults stringForKey:@"password"];
    if (login.length > 0 && password.length > 0) {
        [[ChatTools sharedInstance] disconnect];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // re-login
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *login = [userDefaults stringForKey:@"login"];
    NSString *password = [userDefaults stringForKey:@"password"];
    if (login.length > 0 && password.length > 0) {
        [[ChatTools sharedInstance] login:login password:password];
    }
    // clear address book cache
    [[ContactManager sharedInstance] clearCache];
}

#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}

#endif


- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)dataToken
{
	NSLog(@"Got device token: %@", dataToken);
    self.deviceToken = [[dataToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    self.deviceToken = [self.deviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
}



@end
