//
//  AboutVC.h
//  Yoo
//
//  Created by Arnaud on 26/03/2014.
//  Copyright (c) 2014 Fellow Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "BaseVC.h"

@interface AboutVC : BaseVC<MFMailComposeViewControllerDelegate>{
    UIScrollView *scroll;
}

@end
