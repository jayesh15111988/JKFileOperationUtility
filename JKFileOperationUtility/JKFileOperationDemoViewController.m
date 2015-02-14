//
//  JKFileOperationDemoViewController.m
//  JKFileOperationUtility
//
//  Created by Jayesh Kawli Backup on 2/14/15.
//  Copyright (c) 2015 Jayesh Kawli Backup. All rights reserved.
//

#import "JKFileOperationDemoViewController.h"
#import "JKFileOperation.h"

@interface JKFileOperationDemoViewController ()
@property (nonatomic, strong) NSArray* allFoldersList;
@property (strong, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (assign, nonatomic) NSInteger rowToDelete;
@end

@implementation JKFileOperationDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.rowToDelete = -1;
    self.title = @"File Operation Demo";
    self.tableView.tableFooterView = self.footerView;
    [self getRecentFoldersAndReloadTable];
    //Add right bar button item to navigation bar
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFolder)];

}

#pragma tableView datasource and delegate methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"foldernamecell" forIndexPath:indexPath];
    UILabel* folderNameLabel = (UILabel*)[cell viewWithTag:13];
    NSString* currentFolderName = self.allFoldersList[indexPath.row];
    folderNameLabel.text = currentFolderName;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allFoldersList count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Delete Folder" message:@"Are you sure you want to remove selected folder?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    alert.tag = 14;
    [alert show];
    self.rowToDelete = indexPath.row;
}

-(void)addFolder {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Add New Folder" message:@"Please provide a name for new folder to create in the root directory" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    alert.tag = 13;
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

-(void)getRecentFoldersAndReloadTable {
    self.allFoldersList = [JKFileOperation getListOfAllFolderFromDefaultDirectory];
    [self.tableView reloadData];
}

#pragma UIAlertView delegate method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0) {
        if(alertView.tag == 13) {
            NSString* folderName = [[alertView textFieldAtIndex:0] text];
            if(folderName.length > 0) {
                [JKFileOperation createOrCheckForFolderWithName:folderName];
                [self getRecentFoldersAndReloadTable];
            }
        } else if (alertView.tag == 14 && self.rowToDelete != -1) {
            NSString* folderNameToRemove = self.allFoldersList[self.rowToDelete];
            [JKFileOperation removeFolderFromDefaultDocumentDirectory:folderNameToRemove];
            self.tableView.editing = !self.tableView.editing;
            [self getRecentFoldersAndReloadTable];
            self.rowToDelete = -1;
        }
    } else if(buttonIndex == 0 && alertView.tag == 14) {
        self.tableView.editing = !self.tableView.editing;
    }
}

@end
