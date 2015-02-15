//
//  JKFilesFromFolderViewController.m
//  JKFileOperationUtility
//
//  Created by Jayesh Kawli Backup on 2/14/15.
//  Copyright (c) 2015 Jayesh Kawli Backup. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "JKFilesFromFolderViewController.h"
#import "JKFileNameTableViewCell.h"
#import "JKFileOperation.h"

@interface JKFilesFromFolderViewController ()<SWTableViewCellDelegate>
@property (weak, nonatomic) IBOutlet UIView *footer;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray* filesCollection;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end

@implementation JKFilesFromFolderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.selectedFolder;
     self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFile)];
    self.tableView.tableFooterView = self.footer;
    [self getAllFilesFromCurrentFolderAndReloadTable];
}

-(void)getAllFilesFromCurrentFolderAndReloadTable {
    self.filesCollection = [JKFileOperation getListOfAllFilesFromFolder:self.selectedFolder];
    [self.tableView reloadData];
    [self.activityIndicator stopAnimating];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JKFileNameTableViewCell* fileNameCell = (JKFileNameTableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"filedetailscell" forIndexPath:indexPath];
    fileNameCell.rightUtilityButtons = [self rightButtons];
    fileNameCell.delegate = self;
    
    NSString* fileFullPathInDocumentDirectory = self.filesCollection[indexPath.row];
    NSString* nameOfFile = [[fileFullPathInDocumentDirectory lastPathComponent] stringByDeletingPathExtension];
    fileNameCell.fileName.text = nameOfFile;
    fileNameCell.fileImage.image = [UIImage imageWithContentsOfFile:fileFullPathInDocumentDirectory];
    return fileNameCell;
}

- (NSArray *)rightButtons {
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0] title:@"Rename"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f] title:@"Delete"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:0.93 green:0.55 blue:0.047 alpha:1.0] title:@"Move file"];
    return rightUtilityButtons;
}


- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    //Rename
    NSInteger cellIndex = [self.tableView indexPathForCell:cell].row;
    NSString* fileName = [self.filesCollection[cellIndex] lastPathComponent];
    
    
    if(index == 0) {
        //Rename operation
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Rename a File" message:@"Please provide a new name for a current file" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].text = [fileName stringByDeletingPathExtension];
        [[alert rac_buttonClickedSignal] subscribeNext:^(NSNumber* indexSelected) {
            if([indexSelected integerValue] > 0) {
                NSString* nameForNewFile = [[alert textFieldAtIndex:0] text];
                if((![fileName isEqualToString:nameForNewFile]) && nameForNewFile.length > 0) {
                    [JKFileOperation renameFile:fileName toDestinationFileName:[NSString stringWithFormat:@"%@.png",nameForNewFile] andFolderName:self.selectedFolder];
                    [self getAllFilesFromCurrentFolderAndReloadTable];
                }
            }
        }];
        [alert show];
    } else if (index == 1) {
        //File delete operation
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Delete File" message:@"Are you sure you want to remove selected File?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
        [[alert rac_buttonClickedSignal] subscribeNext:^(NSNumber* indexSelected) {
            if([indexSelected integerValue] > 0) {
                [JKFileOperation removeFile:fileName fromFolder:self.selectedFolder];
                [self getAllFilesFromCurrentFolderAndReloadTable];
            } else {
                [cell hideUtilityButtonsAnimated:YES];
            }
        }];
        [alert show];
    } else if (index == 2) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Move a File" message:@"Please provide a name of a folder to move file into" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].text = self.selectedFolder;
        [[alert rac_buttonClickedSignal] subscribeNext:^(NSNumber* indexSelected) {
            if([indexSelected integerValue] > 0) {
                NSString* updatedFolder = [[alert textFieldAtIndex:0] text];
                if(![updatedFolder isEqualToString:self.selectedFolder] && updatedFolder.length > 0) {
                    [JKFileOperation moveFile:fileName fromFolder:self.selectedFolder toDestinationFolder:updatedFolder];
                    [self getAllFilesFromCurrentFolderAndReloadTable];
                }
            }
        }];
        [alert show];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.filesCollection count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSString*)generateRandomString {
    return [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
}

-(void)addFile {
    //Adding files
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"File URL" message:@"Please provide a URL where you are trying to download file from" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[alert rac_buttonClickedSignal] subscribeNext:^(NSNumber* indexSelected) {
        if([indexSelected integerValue] > 0) {
            NSString* inputURLValue = [[alert textFieldAtIndex:0] text];
            if(inputURLValue > 0) {
                [self.activityIndicator startAnimating];
                [JKFileOperation storeFileWithURL:inputURLValue inFolderWithName:self.selectedFolder andImageFileName:[self generateRandomString] completion:^(FileCreationStatus status) {
                    if(status == NewFileCreated) {
                        dispatch_async(dispatch_get_main_queue(), ^(void) {
                            [self getAllFilesFromCurrentFolderAndReloadTable];
                        });
                    }
                }];
            }
        }
    }];
    [alert show];
}
@end
