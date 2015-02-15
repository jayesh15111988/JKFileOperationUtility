//
//  JKFileOperationDemoViewController.m
//  JKFileOperationUtility
//
//  Created by Jayesh Kawli Backup on 2/14/15.
//  Copyright (c) 2015 Jayesh Kawli Backup. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "JKFileOperationDemoViewController.h"
#import "JKFileOperation.h"
#import "JKFolderNameTableViewCell.h"
#import "JKFilesFromFolderViewController.h"

@interface JKFileOperationDemoViewController ()<SWTableViewCellDelegate>
@property (weak, nonatomic) IBOutlet UIView *noFolderFoundView;
@property (nonatomic, strong) NSArray* allFoldersList;
@property (strong, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation JKFileOperationDemoViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.title = @"File Operation Demo";
    self.tableView.tableFooterView = self.footerView;
    [self getRecentFoldersAndReloadTable];
    //Add right bar button item to navigation bar
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFolder)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteAllFolders)];

}

#pragma tableView datasource and delegate methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JKFolderNameTableViewCell* cell = (JKFolderNameTableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"foldernamecell" forIndexPath:indexPath];
    NSString* currentFolderName = self.allFoldersList[indexPath.row];
    cell.folderNameLabel.text = currentFolderName;
    cell.rightUtilityButtons = [self rightButtons];
    cell.delegate = self;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allFoldersList count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    JKFilesFromFolderViewController* filesViewerViewController = (JKFilesFromFolderViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"filescollection"];
    NSString* selectedFolder = self.allFoldersList[indexPath.row];
    filesViewerViewController.selectedFolder = selectedFolder;
    [self.navigationController pushViewController:filesViewerViewController animated:YES];
}

- (NSArray *)rightButtons {
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
    [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0] title:@"Rename"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
    [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] title:@"Delete"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
    [UIColor colorWithRed:0.93 green:0.55 blue:0.047 alpha:1.0] title:@"Remove All"];
    return rightUtilityButtons;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    //Rename
    NSInteger cellIndex = [self.tableView indexPathForCell:cell].row;
    NSString* folderName = self.allFoldersList[cellIndex];
    if(index == 0) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rename a Folder" message:@"Please provide a new name for a current folder" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].text = folderName;
        [[alert rac_buttonClickedSignal] subscribeNext:^(NSNumber* indexSelected) {
            if([indexSelected integerValue] > 0) {
                NSString* nameForNewFolder = [[alert textFieldAtIndex:0] text];
                if((![folderName isEqualToString:nameForNewFolder]) && nameForNewFolder.length > 0) {
                    [JKFileOperation renameFolderWithSourceName:folderName andDestinationFolder:nameForNewFolder];
                    [self getRecentFoldersAndReloadTable];
                }
            }
        }];
        [alert show];
    } else if (index == 1) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Delete Folder" message:@"Are you sure you want to remove selected folder?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
        [[alert rac_buttonClickedSignal] subscribeNext:^(NSNumber* indexSelected) {
            if([indexSelected integerValue] > 0) {
                [JKFileOperation removeFolderFromDefaultDocumentDirectory:folderName];
                [self  getRecentFoldersAndReloadTable];
            } else {
                [cell hideUtilityButtonsAnimated:YES];
            }
        }];
        [alert show];
    } else if (index ==2) {
        //Remove all files from folder
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Delete All" message:@"Are you sure you want to remove all files from selected folder?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
        [[alert rac_buttonClickedSignal] subscribeNext:^(NSNumber* indexSelected) {
            if([indexSelected integerValue] > 0) {
                [JKFileOperation removeAllFilesFromFolder:folderName];
                [self getRecentFoldersAndReloadTable];
            }
        }];
        [alert show];
    }
}

-(void)addFolder {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Add New Folder" message:@"Please provide a name for new folder to create in the root directory" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[alert rac_buttonClickedSignal] subscribeNext:^(NSNumber* indexSelected) {
        if([indexSelected integerValue] > 0) {
            NSString* folderName = [[alert textFieldAtIndex:0] text];
            if(folderName.length > 0) {
                [JKFileOperation createOrCheckForFolderWithName:folderName];
                [self getRecentFoldersAndReloadTable];
            }
        }
    }];
    [alert show];
}

-(void)deleteAllFolders {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Delete All Folders" message:@"Are you sure you want to remove all folders listed here?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    [[alert rac_buttonClickedSignal] subscribeNext:^(NSNumber* indexSelected) {
        if([indexSelected integerValue] > 0) {
            for(NSString* individualFolderName in self.allFoldersList) {
                [JKFileOperation removeFolderFromDefaultDocumentDirectory:individualFolderName];
            }
            [self getRecentFoldersAndReloadTable];
        }
    }];
    [alert show];
}

-(void)getRecentFoldersAndReloadTable {
    self.allFoldersList = [JKFileOperation getListOfAllFolderFromDefaultDirectory];
    [self.tableView reloadData];
    self.noFolderFoundView.hidden = ([self.allFoldersList count] != 0);
}

@end
