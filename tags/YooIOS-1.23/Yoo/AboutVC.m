//
//  AboutVC.m
//  Yoo
//
//  Created by Arnaud on 26/03/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import "AboutVC.h"

@interface AboutVC ()

@end

@implementation AboutVC

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"ABOUT_APP", nil);
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    UIImageView *logoView = [[UIImageView alloc] initWithFrame:CGRectMake(80, 78, 161, 124)];
    [logoView setImage:[UIImage imageNamed:@"Logo.png"]];
    [logoView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    [self.view addSubview:logoView];



    
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    UILabel *versionLbl = [[UILabel alloc] initWithFrame:CGRectMake(8, 204, 312, 24)];
    [versionLbl setFont:[UIFont fontWithName:@"Avenir" size:[UIFont systemFontSize]]];
    [versionLbl setText:[NSString stringWithFormat:@"Version %@", version]];
    [versionLbl setTextAlignment:NSTextAlignmentCenter];
    [versionLbl setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    [self.view addSubview:versionLbl];
    
    UILabel *fellowLbl = [[UILabel alloc] initWithFrame:CGRectMake(8, 224, 312, 24)];
    [fellowLbl setFont:[UIFont fontWithName:@"Avenir" size:[UIFont systemFontSize]]];
    [fellowLbl setText:@"Copyright 2014 - Fellow Consulting"];
    [fellowLbl setTextAlignment:NSTextAlignmentCenter];
    [fellowLbl setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    [self.view addSubview:fellowLbl];
    
    if ([MFMailComposeViewController canSendMail]) {
        UIButton *contactBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [contactBtn setFrame:CGRectMake(80, 270, 160, 44)];
        [contactBtn setTitle:NSLocalizedString(@"CONTACT_US", nil) forState:UIControlStateNormal];
        [contactBtn addTarget:self action:@selector(contactUs) forControlEvents:UIControlEventTouchUpInside];
        [contactBtn setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
        [self.view addSubview:contactBtn];
    }

//    UIButton *recommendBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    [recommendBtn setFrame:CGRectMake(80, 250, 160, 44)];
//    [recommendBtn setTitle:@"Recommend" forState:UIControlStateNormal];
//    [mainView addSubview:recommendBtn];

}

- (void)contactUs {
    // To address
    NSArray *toRecipents = [NSArray arrayWithObject:@"sales@fellow-consulting.de"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:@"Yoo"];
    [mc setToRecipients:toRecipents];
    
    if (mc != nil) {
    
        // Present mail view controller on screen
        [self presentViewController:mc animated:YES completion:NULL];
    }
    
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
