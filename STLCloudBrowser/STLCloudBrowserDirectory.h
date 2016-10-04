//
//  STLCloudBrowserDirectory.h
//  STLCloudBrowser
//
//  Created by Vishal Patil on 10/25/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STLCloudBrowserDirectory : NSObject
@property BOOL isRoot;
@property NSString *uuid;
@property NSString *drivePath;
@property NSString *url;
@property NSMutableArray *subDirectories;
@property NSMutableArray *files;
@end
