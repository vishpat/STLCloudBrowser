//
//  STLCloudBrowserLocalDrive.m
//  STLCloudBrowser
//
//  Created by Vishal Patil on 11/5/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import "STLCloudBrowserLocalDrive.h"

@interface STLCloudBrowserLocalDrive() {
    NSOperationQueue *operationQueue;
    BOOL fileBeingLoaded;
    BOOL currentStatus;
}
- (IBAction)copyFile:(id)sender;
- (IBAction)copyFileComplete:(id)sender;
@end

@implementation STLCloudBrowserLocalDrive

-(id)initWithViewController:(UIViewController *)rootViewController {
    
    if (self = [super init]) {
        fileBeingLoaded = NO;
        currentStatus = NO;
        operationQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

-(BOOL)startLoadingDirectory:(STLCloudBrowserDirectory*)dir {
    BOOL status = NO;
    assert(status == YES);
    return status;
}

-(IBAction)copyFile:(STLCloudBrowserFile*)file {
    @autoreleasepool {
        NSError *error;
    
        NSLog(@"Local Drive: Copying %@ to %@", file.url, file.localPath);
    
        NSFileManager *fileManager = [NSFileManager defaultManager];
    
        if ([file.url compare:file.localPath] == NSOrderedSame) {
            currentStatus = YES;
        } else {
            currentStatus = [fileManager copyItemAtPath:file.url toPath:file.localPath error:&error];
        }
        
        [self performSelectorOnMainThread:@selector(copyFileComplete:) withObject:file waitUntilDone:YES];
    }
}

-(IBAction)copyFileComplete:(STLCloudBrowserFile*)file {
    NSLog(@"Local Drive: calling file loaded");
    
    [self.delegate fileLoaded:file status:currentStatus];
    fileBeingLoaded = NO;
    currentStatus = NO;
}

-(BOOL)startLoadingFile:(STLCloudBrowserFile*)file {
    NSLog(@"Local Drive: Starting to load %@", file.uuid);
    
    BOOL status = NO;
    
    assert(fileBeingLoaded == NO);
    
    currentStatus = NO;
    
    [self performSelectorInBackground:@selector(copyFile:) withObject:file];
    return status;
}

@end
