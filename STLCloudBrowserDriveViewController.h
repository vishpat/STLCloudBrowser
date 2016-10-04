//
//  STLCloudBrowserDriveViewController.h
//  STLCloudBrowser
//
//  Created by Vishal Patil on 9/9/13.
//  Copyright (c) 2013 Akruty. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface STLCloudBrowserDriveViewController : UICollectionViewController
@property (strong, nonatomic) IBOutlet UICollectionView *driveCollectionView;
-(IBAction)loadSTLFile:(NSString*)path;
@end
