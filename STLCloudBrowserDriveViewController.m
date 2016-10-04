//
//  STLCloudBrowserDriveViewController.m
//  STLCloudBrowser
//
//  Created by Vishal Patil on 9/9/13.
//  Copyright (c) 2013 Akruty. All rights reserved.
//

#import "STLCloudBrowserDriveViewController.h"
#import "STLCloudBrowserDriveCell.h"
#import "STLCloudBrowserDirectoryViewController.h"
#import "STLCloudBrowserSTLViewController.h"
#import "STLCloudBrowserDriveCell.h"
#import "STLCloudBrowserGoogleDrive.h"
#import "STLCloudBrowserDropBoxDrive.h"
#import "STLCloudBrowserLocalDrive.h"
#import "STLCloudBrowserDrive.h"
#import "STLCloudBrowserUtils.h"


static NSString *cellXib = @"STLCloudBrowserDriveCell";
static NSString *cellIndentifier = @"driveCell";

@interface STLCloudBrowserDriveViewController () {
    NSOperationQueue *operationQueue;
}
-(IBAction)pingStatsServer:(id)sender;
-(IBAction)pingDone:(id)sender;

@end

@implementation STLCloudBrowserDriveViewController
@synthesize driveCollectionView = _driveCollectionView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(IBAction)pingStatsServer:(id)sender {
    NSString *uuid = [[UIDevice currentDevice] name];
    uuid = [uuid stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    
    NSString *pingURL = [NSString stringWithFormat:@"http://akrutystats.appspot.com/b304ce5c671add44a5babd59bbe29b71f712d3a7d3b3a92a699a2153?uuid=%@", uuid];
    
#if (TARGET_IPHONE_SIMULATOR)
    pingURL = [NSString stringWithFormat:@"http://localhost:9080/b304ce5c671add44a5babd59bbe29b71f712d3a7d3b3a92a699a2153?uuid=%@", uuid];
#endif
    
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:pingURL]];
    NSURLResponse * response = nil;
    NSError * error = nil;
    [NSURLConnection sendSynchronousRequest:urlRequest
                          returningResponse:&response
                                      error:&error];
    if (error != nil) {
        NSLog(@"ERROR communicating with the stats server: %@", [error localizedDescription]);
    }
    
    [self performSelectorOnMainThread:@selector(pingDone:) withObject:nil waitUntilDone:YES];
}

-(IBAction)pingDone:(id)sender
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"APP_NAME", nil);
    [UIApplication sharedApplication].keyWindow.rootViewController.title =  NSLocalizedString(@"APP_NAME", nil);

    UINib *cellNib = [UINib nibWithNibName:cellXib bundle:nil];
    [_driveCollectionView registerNib:cellNib forCellWithReuseIdentifier:cellIndentifier];
    
	// Do any additional setup after loading the view.
    operationQueue = [[NSOperationQueue alloc] init];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                        initWithTarget:self
                                        selector:@selector(pingStatsServer:)
                                        object:nil];
    [operationQueue addOperation:operation];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 2;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    STLCloudBrowserDriveCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIndentifier
                                                                               forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case 0:
            cell.driveImageView.image = [UIImage imageNamed:@"dropbox_icon.png"];
            break;
        case 1:
            cell.driveImageView.image = [UIImage imageNamed:@"google_drive_icon.png"];
            break;
        default:
            break;
    }

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootViewController = window.rootViewController;
    
    STLCloudBrowserDrive *drive;
    STLCloudBrowserDirectory *rootDir = [[STLCloudBrowserDirectory alloc] init];
    
    switch (indexPath.row) {
        case 0:
            drive = [[STLCloudBrowserDropBoxDrive alloc] initWithViewController:rootViewController];
            rootDir.uuid = @"/";
            rootDir.isRoot = YES;
            rootDir.drivePath = NSLocalizedString(@"DROPBOX", nil);
            break;
        case 1 :
            drive = [[STLCloudBrowserGoogleDrive alloc] initWithViewController:rootViewController];
            rootDir.uuid = @"root";
            rootDir.isRoot = YES;
            rootDir.drivePath = NSLocalizedString(@"GOOGLE_DRIVE", nil);
            break;
        default:
            break;
    }
    
    if (drive && [drive isAuthorized]) {
        STLCloudBrowserDirectoryViewController *dirViewController = [[STLCloudBrowserDirectoryViewController alloc]
                                                                     initWithNibName:@"DirectoryViewiPhone"
                                                                     bundle:nil];
        dirViewController.drive = drive;
        dirViewController.dir = rootDir;
        
        [self.navigationController pushViewController:dirViewController animated:YES];
    } 

}

-(IBAction)loadSTLFile:(NSString*)path
{
    STLCloudBrowserFile *bfile = [[STLCloudBrowserFile alloc] init];
    bfile.localPath = path;
    
    NSString *xib = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ?
    @"STLViewiPad" : @"STLViewiPhone";
    
    STLCloudBrowserSTLViewController *stlViewController = [[STLCloudBrowserSTLViewController alloc]
                                                           initWithNibName:xib bundle:nil];
    
    stlViewController.drive = [[STLCloudBrowserLocalDrive alloc] initWithViewController:stlViewController];
    stlViewController.stlFile = bfile;
    
    [self.navigationController pushViewController:stlViewController animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
}

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    static UIEdgeInsets edgeInsets;
    BOOL iPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    if (iPad) {
        edgeInsets = UIEdgeInsetsMake(350, 350, 350, 350);
    } else {
        edgeInsets = UIEdgeInsetsMake(150, 150, 150, 150);
    }
    
    return edgeInsets;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

@end
