//
//  STLCloudBrowserDrive.h
//  STLCloudBrowser
//
//  Created by Vishal Patil on 10/31/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STLCloudBrowserDirectory.h"
#import "STLCloudBrowserFile.h"

@protocol STLCloudBrowserDriveDelegate
-(void)dirLoaded:(STLCloudBrowserDirectory*)dir status:(BOOL)boolStatus;
-(void)fileLoaded:(STLCloudBrowserFile*)file status:(BOOL)boolStatus;
@end

@interface STLCloudBrowserDrive : NSObject

@property id <STLCloudBrowserDriveDelegate> delegate;

-(id)initWithViewController:(UIViewController *)rootViewController;
-(BOOL)isAuthorized;
-(BOOL)startLoadingDirectory:(STLCloudBrowserDirectory*)dir;
-(BOOL)startLoadingFile:(STLCloudBrowserFile*)file;
-(BOOL)signOut;
@end
