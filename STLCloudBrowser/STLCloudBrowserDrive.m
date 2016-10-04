//
//  STLCloudBrowserDrive.m
//  STLCloudBrowser
//
//  Created by Vishal Patil on 10/31/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import "STLCloudBrowserDrive.h"

@implementation STLCloudBrowserDrive
@synthesize delegate = _delegate;

-(id)initWithViewController:(UIViewController *)rootViewController {
    return nil;
}

-(BOOL)isAuthorized {
    return NO;
}

-(BOOL)startLoadingDirectory:(STLCloudBrowserDirectory*)dir {
    return NO;
}

-(BOOL)startLoadingFile:(STLCloudBrowserFile*)file {
    return NO;
}

-(BOOL)signOut {
    return NO;
}

@end
