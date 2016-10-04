//
//  STLCloudBrowserUtils.m
//  STLCloudBrowser
//
//  Created by Vishal Patil on 11/5/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import "STLCloudBrowserUtils.h"

@implementation STLCloudBrowserUtils

+(void)showErrorMessage:(NSString *)message {

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"APP_NAME", nil)
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"DISMISS", nil)
                                          otherButtonTitles:nil];
    [alert show];

}
@end
