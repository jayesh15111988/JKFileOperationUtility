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

@interface JKFilesFromFolderViewController ()
@property (weak, nonatomic) IBOutlet UIView *footer;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray* filesCollection;
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
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JKFileNameTableViewCell* fileNameCell = (JKFileNameTableViewCell*) [tableView dequeueReusableCellWithIdentifier:@"filedetailscell" forIndexPath:indexPath];
    NSString* fileFullPathInDocumentDirectory = self.filesCollection[indexPath.row];
    NSString* nameOfFile = [[fileFullPathInDocumentDirectory lastPathComponent] stringByDeletingPathExtension];
    fileNameCell.fileName.text = nameOfFile;
    fileNameCell.fileImage.image = [UIImage imageWithContentsOfFile:fileFullPathInDocumentDirectory];
    return fileNameCell;
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
