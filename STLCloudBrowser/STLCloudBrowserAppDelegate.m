//
//  STLCloudBrowserAppDelegate.m
//  STLCloudBrowser
//
//  Created by Vishal Patil on 10/24/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import "STLCloudBrowserAppDelegate.h"
#import "STLCloudBrowserIAPHelper.h"
#import <DropboxSDK/DropboxSDK.h>
#import "iRate.h"

@implementation STLCloudBrowserAppDelegate

-(void)clearDocumentDirectory:(NSString*)exceptFile {
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:documentsDirectory];
    NSString *file, *fileName;
    
    while (file = [dirEnum nextObject]) {
        
        fileName = [file lastPathComponent];
        if ([fileName caseInsensitiveCompare:exceptFile] == NSOrderedSame) {
            continue;
        }
        
        if ([[file pathExtension] caseInsensitiveCompare: @"stl"] == NSOrderedSame) {
            file = [documentsDirectory stringByAppendingPathComponent:file];
            NSLog(@"Removing file %@", file);
            [fileManager removeItemAtPath:file error:&error];
        }
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[STLCloudBrowserIAPHelper sharedHelper] productsLoaded] == NO) {
        [[STLCloudBrowserIAPHelper sharedHelper] requestProducts];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:[STLCloudBrowserIAPHelper sharedHelper]];
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
   // NSLog(@"handleOpenURL called using %@", [url absoluteString]);
    
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
        }
        return YES;
    }
    // Add whatever other url handling code your app requires here
    
    NSError *error;
    
    // Override point for customization after application launch.
    if ([[STLCloudBrowserIAPHelper sharedHelper] productsLoaded] == NO) {
        [[STLCloudBrowserIAPHelper sharedHelper] requestProducts];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:[STLCloudBrowserIAPHelper sharedHelper]];
    }
    
    if ([url isFileURL] && [url checkResourceIsReachableAndReturnError:&error] == YES)
    {
        [self clearDocumentDirectory:[[url path] lastPathComponent]];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fileName = [url lastPathComponent];
        NSURL *destFileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:fileName]];
        NSString *destFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
        
        if ([fileManager copyItemAtURL:url toURL:destFileURL error:&error] == NO) {
            NSLog(@"Problem copying the file from %@ to %@", [url absoluteString], [destFileURL absoluteString]);
        } else {
            NSLog(@"Successfully copied from %@ to %@", [url absoluteString], [destFileURL absoluteString]);
            [[self.window.rootViewController.childViewControllers objectAtIndex:0] performSelector:@selector(loadSTLFile:) withObject:destFilePath];
        }
    }

    return NO;
}

+ (void)initialize
{
    //configure iRate
    [iRate sharedInstance].daysUntilPrompt = 5;
    [iRate sharedInstance].usesUntilPrompt = 15;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
