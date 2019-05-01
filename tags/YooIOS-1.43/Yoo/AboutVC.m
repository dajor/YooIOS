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
    
    scroll = [[UIScrollView alloc]initWithFrame:[self contentRect]];
    scroll.autoresizingMask  = UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:scroll];
    scroll.backgroundColor = [UIColor whiteColor];
    CGSize size = [[UIScreen mainScreen] bounds].size;
    
    
    float y=10;
    
    UIImageView *logoView = [[UIImageView alloc] initWithFrame:CGRectMake(80, y, 161, 124)];
    [logoView setImage:[UIImage imageNamed:@"Logo.png"]];
    [logoView setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    [scroll addSubview:logoView];
    
    y+=124;
    
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    UILabel *versionLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, y, size.width, 24)];
    [versionLbl setFont:[UIFont fontWithName:@"Avenir" size:[UIFont systemFontSize]]];
    [versionLbl setText:[NSString stringWithFormat:@"Version %@", version]];
    [versionLbl setTextAlignment:NSTextAlignmentCenter];
    [versionLbl setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    [scroll addSubview:versionLbl];
    y+=24;
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"copyright" ofType:@"html"];
    NSString *copyrightText  = [NSString stringWithContentsOfFile:path usedEncoding:NSStringEnumerationByLines error:nil];
    
    UIFont *font = [UIFont fontWithName:@"Avenir" size:14.0f];
    float height = [self heightForText:copyrightText font:font :size.width];
    
    
    NSURL *rtfUrl = [[NSBundle mainBundle] URLForResource:@"copyright" withExtension:@"html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:rtfUrl];
    
    UIWebView *_webview = [[UIWebView alloc]initWithFrame:CGRectMake(0, y, size.width, height)];
    [_webview setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    _webview.scrollView.scrollEnabled = NO;
    _webview.scrollView.bounces = NO;
    [_webview loadRequest:request];
    
    [scroll addSubview:_webview];
    y+=height;
    
    if ([MFMailComposeViewController canSendMail]) {
        UIButton *contactBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [contactBtn setFrame:CGRectMake(80, y, 160, 44)];
        [contactBtn setTitle:NSLocalizedString(@"CONTACT_US", nil) forState:UIControlStateNormal];
        [contactBtn addTarget:self action:@selector(contactUs) forControlEvents:UIControlEventTouchUpInside];
        [contactBtn setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
        [scroll addSubview:contactBtn];
        y+=44;
    }
    
    
    [scroll setContentSize:CGSizeMake(size.width, y+10)];
}

-(CGFloat)heightForText:(NSString *)atext font:(UIFont *)font :(float)maxWidth{
    NSString *newCaption = [NSString stringWithFormat:@"%@",atext];
    CGSize constrainedSize = CGSizeMake(maxWidth , 9999);
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, nil];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:newCaption attributes:attributesDictionary];
    CGRect requiredHeight = [string boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    return CGRectGetHeight(requiredHeight);
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
