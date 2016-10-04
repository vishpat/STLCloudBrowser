//
//  STLCloudBrowserDirectoryViewController.m
//  STLCloudBrowser
//
//  Created by Vishal Patil on 10/29/12.
//  Copyright (c) 2012 Akruty. All rights reserved.
//

#import "STLCloudBrowserDirectoryViewController.h"
#import "STLCloudBrowserSTLViewController.h"
#import "STLCloudBrowserDirCell.h"
#import "STLCloudBrowserUtils.h"

@interface STLCloudBrowserDirectoryViewController () {
    UIActivityIndicatorView *activityIndicator;
}
@property IBOutlet UITableView *dirTableView;
-(IBAction)signOut:(id)sender;

@end

@implementation STLCloudBrowserDirectoryViewController
@synthesize drive = _drive;
@synthesize dir = _dir;
@synthesize dirTableView = _dirTableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    
    NSLog(@"View did load called");
    
    self.navigationItem.title = [self.dir.drivePath lastPathComponent];
    self.drive.delegate = self;
    self.navigationItem.title = [self.dir.drivePath lastPathComponent];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [activityIndicator startAnimating];
    [self.drive startLoadingDirectory:self.dir];
}

-(void)dirLoaded:(STLCloudBrowserDirectory*)dir status:(BOOL)boolStatus {
    if (boolStatus == NO) {
        [STLCloudBrowserUtils showErrorMessage:NSLocalizedString(@"DRIVE_CONNECTION_PROBLEM", nil)];
    } else {
        [activityIndicator stopAnimating];
        if (self.dir.isRoot == YES) {
            self.navigationItem.rightBarButtonItem = nil;
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                    initWithTitle:NSLocalizedString(@"SIGN_OUT", nil)
                                                            style:UIBarButtonSystemItemDone
                                                            target:self
                                                            action:@selector(signOut:)];
        }
        
        [self.dirTableView reloadData];
    }
}

-(IBAction)signOut:(id)sender {
    [self.drive signOut];
    [[self navigationController] popViewControllerAnimated:YES];
}

-(void)fileLoaded:(STLCloudBrowserFile*)file status:(BOOL)boolStatus {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dir.subDirectories count] + [self.dir.files count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[STLCloudBrowserDirCell alloc] init];
    int dirCount = [self.dir.subDirectories count];
    int fileCount = [self.dir.files count];
    
    if (indexPath.row < dirCount) {
        STLCloudBrowserDirectory *subDir = [_dir.subDirectories objectAtIndex:indexPath.row];
        cell.textLabel.text = [subDir.drivePath lastPathComponent];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    if (indexPath.row >= dirCount && indexPath.row < (dirCount + fileCount)) {
        int fileIndex = indexPath.row - dirCount;
        STLCloudBrowserFile *file = [_dir.files objectAtIndex:fileIndex];
        cell.textLabel.text = [file.drivePath lastPathComponent];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int dirCount = [self.dir.subDirectories count];
    int fileCount = [self.dir.files count];
    
    if (indexPath.row < dirCount) {
        STLCloudBrowserDirectory *subDir = [_dir.subDirectories objectAtIndex:indexPath.row];
        
        STLCloudBrowserDirectoryViewController *dirViewController = [[STLCloudBrowserDirectoryViewController alloc]
                                                                     initWithNibName:@"DirectoryViewiPhone"
                                                                     bundle:nil];
        dirViewController.drive = self.drive;
        dirViewController.dir = subDir;
        
        [self.navigationController pushViewController:dirViewController animated:YES];
    } else if (indexPath.row >= dirCount && indexPath.row < (dirCount + fileCount)) {
        int fileIndex = indexPath.row - dirCount;
        STLCloudBrowserFile *file = [_dir.files objectAtIndex:fileIndex];
        file.localPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(),
                          [file.drivePath lastPathComponent]];
        
        NSString *xib = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ?
                        @"STLViewiPad" : @"STLViewiPhone";
        
        STLCloudBrowserSTLViewController *stlViewController = [[STLCloudBrowserSTLViewController alloc]
                                                              initWithNibName:xib bundle:nil];
        stlViewController.drive = self.drive;
        stlViewController.stlFile = file;
        [self.navigationController pushViewController:stlViewController animated:YES];
    }
}

@end
