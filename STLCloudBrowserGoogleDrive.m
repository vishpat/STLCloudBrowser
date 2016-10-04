//
//  STLCloudBrowserGoogleDrive.m
//  STLCloudBrowser
//
//  Created by Vishal Patil on 10/25/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import "GTLDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"

#import "STLCloudBrowserGoogleDrive.h"

static NSString *const kKeychainItemName = @"abc";
static NSString *const kClientId = @"124";
static NSString *const kClientSecret = @"456";

@interface STLCloudBrowserGoogleDrive()

@property (weak) UIViewController *rootViewController;
@property (weak, readonly) GTLServiceDrive *driveService;
@property (strong) NSMutableArray *driveFiles;
@property BOOL hasBeenAuthorized;

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error;
@end

@implementation STLCloudBrowserGoogleDrive

@synthesize rootViewController = _rootViewController;
@synthesize driveService = _driveService;
@synthesize driveFiles = _driveFiles;
@synthesize hasBeenAuthorized = _hasBeenAuthorized;

-(void)initGoogleDriveSession {
    GTMOAuth2Authentication *auth =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                          clientID:kClientId
                                                      clientSecret:kClientSecret];
    if ([auth canAuthorize]) {
        [self isAuthorizedWithAuthentication:auth];
    } else {
        SEL finishedSelector = @selector(viewController:finishedWithAuth:error:);
        GTMOAuth2ViewControllerTouch *authViewController =
        [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDriveReadonly
                                                   clientID:kClientId
                                               clientSecret:kClientSecret
                                           keychainItemName:kKeychainItemName
                                                   delegate:self
                                           finishedSelector:finishedSelector];
        [_rootViewController presentViewController:authViewController animated:YES completion:nil];
    }
}

-(id)initWithViewController:(UIViewController *)rootViewController {
    
    if (self = [super init]) {
        _rootViewController = rootViewController;
        [self initGoogleDriveSession];
    }
    
    return self;
}

-(BOOL)isAuthorized {
    return self.hasBeenAuthorized;
}

-(BOOL)signOut {
    BOOL status = NO;
    GTMOAuth2Authentication *auth =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                          clientID:kClientId
                                                      clientSecret:kClientSecret];

    if ([auth canAuthorize]) {
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
        status = YES;
    }
    
    return status;
}

-(BOOL)startLoadingDirectory:(STLCloudBrowserDirectory*)dir {
    BOOL status = YES;
    
    NSLog(@"Google Drive: Loading directory %@, %@", dir.drivePath, dir.uuid);
    
    GTLQueryDrive *query =
    [GTLQueryDrive queryForChildrenListWithFolderId:dir.uuid];
    
    [self.driveService executeQuery:query
        completionHandler:^(GTLServiceTicket *ticket,
                            GTLDriveChildList *children, NSError *error) {
            if (error == nil) {
                dir.subDirectories = [[NSMutableArray alloc] init];
                dir.files = [[NSMutableArray alloc] init];
                
                NSLog(@"Google Drive: Loaded directory %@", dir.drivePath);

                for (GTLDriveChildReference *child in children) {
                    
                    GTLQuery *query = [GTLQueryDrive queryForFilesGetWithFileId:child.identifier];
                    
                    [self.driveService executeQuery:query
                        completionHandler:^(GTLServiceTicket *ticket, GTLDriveFile *file,
                                            NSError *error) {
                            if (error == nil) {
                                
                                if ([file.mimeType compare:@"application/vnd.google-apps.folder"] == NSOrderedSame) {
                                    STLCloudBrowserDirectory *bdir = [[STLCloudBrowserDirectory alloc] init];
                                    bdir.uuid = child.identifier;
                                    bdir.drivePath = file.title;
                                    bdir.url = file.downloadUrl;
                                    [dir.subDirectories addObject:bdir];
                                    
                                    NSLog(@"Google Drive: Adding subdir %@ to directory %@", bdir.drivePath, dir.drivePath);
                                    
                                } else if ([[file.title pathExtension] caseInsensitiveCompare:@"stl"] == NSOrderedSame) {
                                    STLCloudBrowserFile *bfile = [[STLCloudBrowserFile alloc] init];
                                    bfile.uuid = child.identifier;
                                    bfile.drivePath = file.title;
                                    bfile.url = file.downloadUrl;
                                    [dir.files addObject:bfile];
                                    
                                    NSLog(@"Google Drive: Adding file %@ to directory %@", bfile.drivePath, dir.drivePath);
                                }
                            
                                [self.delegate dirLoaded:dir status:YES];
                                
                            } else {
                                NSLog(@"An error occurred while getting file meta data: %@", error);
                            }
                            
                        }];
                }
            } else {
                NSLog(@"An error %@ occurred while trying to loading dir: %@",
                        error, dir.drivePath);
                [self.delegate dirLoaded:dir status:NO];
            }
    }];
    
    return status;
}

-(BOOL)startLoadingFile:(STLCloudBrowserFile*)file {
    BOOL status = YES;
    
    NSLog(@"Google Drive: Trying to download %@ and url %@", file.uuid, file.url);
    
    GTMHTTPFetcher *fetcher =
    [self.driveService.fetcherService fetcherWithURLString:file.url];
    [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
        if (error == nil) {
            NSLog(@"Google Drive: downloaded %@ to %@", file.url, file.localPath);
            [data writeToFile:file.localPath atomically:YES];
            [self.delegate fileLoaded:file status:YES];
        } else {
            NSLog(@"Google Drive: Error %@ occurred with fetching file: %@", error, file.drivePath);
            [self.delegate fileLoaded:file status:NO];
        }
    }];
    
    return status;
}

- (GTLServiceDrive *)driveService {
    static GTLServiceDrive *service = nil;
    
    if (!service) {
        service = [[GTLServiceDrive alloc] init];
        service.shouldFetchNextPages = YES;
        service.retryEnabled = YES;
    }
    
    return service;
}

- (void)isAuthorizedWithAuthentication:(GTMOAuth2Authentication *)auth {
    [[self driveService] setAuthorizer:auth];
    self.hasBeenAuthorized = YES;
    NSLog(@"Google account authorized");
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    
    [_rootViewController dismissViewControllerAnimated:YES completion:nil];
    if (error == nil) {
        [self isAuthorizedWithAuthentication:auth];
    }
}

@end
