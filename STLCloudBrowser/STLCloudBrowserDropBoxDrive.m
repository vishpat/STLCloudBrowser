//
//  STLCloudBrowserDropBoxDrive.m
//  STLCloudBrowser
//
//  Created by Vishal Patil on 10/24/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>
#import "STLCloudBrowserDropBoxDrive.h"
#import "STLCloudBrowserDirectory.h"
#import "STLCloudBrowserFile.h"

static NSString *const kAppKey = @"abc";
static NSString *const kAppSecret = @"xyz";

@interface STLCloudBrowserDropBoxDrive() <DBRestClientDelegate> {
    DBRestClient *restClient;
    
    BOOL isDirBeingLoaded;
    STLCloudBrowserDirectory *dirBeingLoaded;
       
    BOOL isFileBeingLoaded;
    STLCloudBrowserFile *fileBeingLoaded;
}
@end

@implementation STLCloudBrowserDropBoxDrive

-(void)initDropboxSession {
    DBSession* dbSession = [[DBSession alloc] initWithAppKey:kAppKey
                                                   appSecret:kAppSecret
                                                        root:kDBRootDropbox];
    [DBSession setSharedSession:dbSession];
    
    restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    
    restClient.delegate = self;
    
    dirBeingLoaded = NO;
    fileBeingLoaded = NO;
}

-(BOOL)isAuthorized {
    return [[DBSession sharedSession] isLinked];
}

-(BOOL)signOut {
    BOOL status = YES;
    [[DBSession sharedSession] unlinkAll];
    
    return status;
}

-(id)initWithViewController:(UIViewController *)rootViewController {
    
    if (self = [super init]) {
        [self initDropboxSession];
    
        if (![[DBSession sharedSession] isLinked]) {
            [[DBSession sharedSession] linkFromController:rootViewController];
        }
    }
    
    return self;
}

-(BOOL)startLoadingDirectory:(STLCloudBrowserDirectory*)dir {
    BOOL status = NO;
    
    dirBeingLoaded = dir;
    NSLog(@"Dropbox: Loading directory %@", dir.uuid);
    
    if ([[DBSession sharedSession] isLinked]) {
        assert(isDirBeingLoaded == NO);
        isDirBeingLoaded = YES;
        [restClient loadMetadata:dir.uuid];
        status = YES;
    } else {
        NSLog(@"Dropbox: Loading directory failed : Dropbox account not linked");
    }
    
    return status;
}

-(BOOL)startLoadingFile:(STLCloudBrowserFile*)file {
    BOOL status = NO;
    
    fileBeingLoaded = file;
    NSLog(@"Dropbox: Downloading file %@ %@ to %@", file.uuid, file.drivePath, file.localPath);

    if ([[DBSession sharedSession] isLinked]) {
        assert(isFileBeingLoaded == NO);
        isFileBeingLoaded = YES;
        [restClient loadFile:file.uuid intoPath:file.localPath];
        status = YES;
    } else {
        NSLog(@"Dropbox: Loading file failed : Dropbox account not linked");
    }
    
    return status;
}

#pragma mark DBRestClientDelegate methods

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata {
    dirBeingLoaded.subDirectories = [[NSMutableArray alloc] init];
    dirBeingLoaded.files = [[NSMutableArray alloc] init];
    
    NSLog(@"Dropbox: Loaded metadata %@, count = %d", metadata.path, [metadata.contents count]);
    
    if (metadata.isDirectory) {
        for (DBMetadata *file in metadata.contents) {
            
            if (file.isDirectory) {
                NSLog(@"Dropbox: Adding subdirectory %@", file.path);
                STLCloudBrowserDirectory *dir = [[STLCloudBrowserDirectory alloc] init];
                dir.uuid = file.path;
                dir.drivePath = file.path;
                dir.url = file.path;
                [dirBeingLoaded.subDirectories addObject:dir];
            } else {
                NSLog(@"Dropbox: Adding file %@", file.path);
                if ([[file.path pathExtension] caseInsensitiveCompare:@"stl"] == NSOrderedSame) {
                    STLCloudBrowserFile *dirfile = [[STLCloudBrowserFile alloc] init];
                    dirfile.uuid = file.path;
                    dirfile.drivePath = file.path;
                    dirfile.url = file.path;
                    [dirBeingLoaded.files addObject:dirfile];
                }
            }
        }
    }
    
    NSLog(@"Dropbox: Loaded directory calling delegate with dir count %d, file count %d",
            [dirBeingLoaded.subDirectories count], [dirBeingLoaded.files count]);
    
    dirBeingLoaded.uuid = metadata.path;
    dirBeingLoaded.url = metadata.path;
    
    [self.delegate dirLoaded:dirBeingLoaded status:YES];
    isDirBeingLoaded = NO;
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path {
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {
    [self.delegate dirLoaded:dirBeingLoaded status:NO];
    isDirBeingLoaded = NO;
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath {
    NSLog(@"Dropbox : Downloaded file %@ at %@", fileBeingLoaded.drivePath, localPath);
    
    assert([fileBeingLoaded.localPath compare:localPath] == NSOrderedSame);
    [self.delegate fileLoaded:fileBeingLoaded status:YES];
    isFileBeingLoaded = NO;
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    NSLog(@"Dropbox : Failed to downloaded file %@", fileBeingLoaded.drivePath);
    [self.delegate fileLoaded:fileBeingLoaded status:NO];
    isFileBeingLoaded = NO;
}

@end


