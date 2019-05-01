//
//  FacebookUtils.m
//  OneXTwo
//
//  Created by Arnaud on 28/10/13.
//  Copyright (c) 2013 Fellow Consulting. All rights reserved.
//

#import "FacebookUtils.h"
#import "MBProgressHUD.h"
#import "UITools.h"
#import <Social/Social.h>

@implementation FacebookUtils

static FacebookUtils *instance = nil;

+ (FacebookUtils *)sharedInstance {
    if (instance == nil) {
        instance = [[FacebookUtils alloc] init];
    }
    return instance;
}

- (id)init {
    self = [super init];
    self.listeners = [NSMutableArray array];
    self.facebookAccount = nil;
    [self setup];
    return self;
}

- (void)addListener:(NSObject <FacebookListener> *)listener {
    [self.listeners addObject:listener];
}

- (void)removeListener:(NSObject<FacebookListener> *)listener {
    [self.listeners removeObject:listener];
}

- (void)setup {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *facebookTypeAccount = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];

    [accountStore requestAccessToAccountsWithType:facebookTypeAccount
                                          options:@{ACFacebookAppIdKey: @"231979993652042", ACFacebookPermissionsKey: @[@"email"]}
                                       completion:^(BOOL granted, NSError *error) {
                                           if (granted) {
                                               NSArray *accounts = [accountStore accountsWithAccountType:facebookTypeAccount];
                                               self.facebookAccount = [accounts lastObject];
                                               for (NSObject <FacebookListener> *listener in self.listeners) {
                                                   [listener fbInitComplete:YES];
                                               }
                                           } else {
                                               NSLog(@"Error: %@", error);
                                               for (NSObject <FacebookListener> *listener in self.listeners) {
                                                   [listener fbInitComplete:NO];
                                               }
                                           }
                                       }];
}



- (void)getGraph:(NSString *)path selector:(SEL)aSelector fbId:(NSString *)fbId {


    NSURL *url = [NSURL URLWithString:path];
    
    NSString *accessToken = [NSString stringWithFormat:@"%@", self.facebookAccount.credential.oauthToken];
    NSDictionary *parameters = @{@"access_token": accessToken, @"width":@"200", @"height":@"200"};
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                              requestMethod:SLRequestMethodGET
                                                        URL:url
                                                 parameters:parameters];
    
    request.account = self.facebookAccount;
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {

        if (error == nil) {
            NSError *nsError = nil;
            if (fbId) {
                UIImage *image = [UIImage imageWithData:responseData];
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:image, @"picture", fbId, @"id", nil];
                for (NSObject <FacebookListener> *listener in self.listeners) {
                    [listener performSelectorOnMainThread:aSelector withObject:dict waitUntilDone:NO];
                }
            } else {
                NSObject *message = [NSJSONSerialization
                                     JSONObjectWithData:responseData
                                     options:0
                                     error:&nsError];
                NSDictionary *dict = (NSDictionary *)message;
                for (NSObject <FacebookListener> *listener in self.listeners) {
                    [listener performSelectorOnMainThread:aSelector withObject:dict waitUntilDone:NO];
                }
            }
        } else {
            for (NSObject <FacebookListener> *listener in self.listeners) {
                [listener performSelectorOnMainThread:aSelector withObject:nil waitUntilDone:NO];
            }
        }
        
        
    }];
}

- (void)getPicture:(NSString *)fbId {
    [self getGraph:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", fbId] selector:@selector(fbGetPicture:) fbId:fbId];
}


- (void)getUserInfo {
    [self getGraph:@"https://graph.facebook.com/me" selector:@selector(fbGetUserInfo:) fbId:nil];
}

- (void)getFriends {
    [self getGraph:@"https://graph.facebook.com/me/friends" selector:@selector(fbGetFriends:) fbId:nil];
}

@end
