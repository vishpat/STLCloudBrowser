//
//  STLCloudBrowserDirectoryViewController.h
//  STLCloudBrowser
//
//  Created by Vishal Patil on 10/29/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STLCloudBrowserDrive.h"

@class STLCloudBrowserDirectory;

@interface STLCloudBrowserDirectoryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, STLCloudBrowserDriveDelegate>
@property STLCloudBrowserDirectory *dir;
@property STLCloudBrowserDrive *drive;
@end
