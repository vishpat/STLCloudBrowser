//
//  STLCloudBrowserSTLViewController.h
//  STLCloudBrowser
//
//  Created by Vishal Patil on 11/2/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <UIKit/UIKit.h>
#import "STLCloudBrowserDrive.h"
#import "STLCloudBrowserFile.h"

@interface STLCloudBrowserSTLViewController : UIViewController <GLKViewDelegate, STLCloudBrowserDriveDelegate, UIAlertViewDelegate>
@property STLCloudBrowserFile *stlFile;
@property STLCloudBrowserDrive *drive;
@property BOOL isLocalfile;
@property IBOutlet GLKView *glview;
@property IBOutlet UIActivityIndicatorView *loadActivityIndicator;
@property IBOutlet UILabel *warningLabel;
@property IBOutlet UILabel *evaluationCopyLabel;
@end
