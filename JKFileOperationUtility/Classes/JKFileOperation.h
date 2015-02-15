//
//  JKFileOperation.h
//  JKFileOperationUtility
//
//  Created by Jayesh Kawli Backup on 2/14/15.
//  Copyright (c) 2015 Jayesh Kawli Backup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

enum {
    NewFolderCreated,
    FolderDidNotCreateWithError,
    FolderExistsDidNotCreateNew
};
typedef NSInteger FolderCreationStatus;

enum {
    NewFileCreated,
    FileDidNotCreateWithError,
    FileExistsDidNotCreateNew
};
typedef NSInteger FileCreationStatus;

enum {
    OperationSuccessful,
    OperationFailed,
    OperationNotRequired
};
typedef NSInteger OperationStatus;



@interface JKFileOperation : NSObject

+ (FolderCreationStatus)createOrCheckForFolderWithName:(NSString*)newFolderName;
//We will make it block based API, as downloading images from remote URL can take longer time and need to run that operation on background thread
+ (void)storeFileWithURL:(NSString*)fileSourceURL inFolderWithName:(NSString*)folderName andImageFileName:(NSString*)imageFileName completion:(void (^)(FileCreationStatus status))completion;
+ (FileCreationStatus)storeImageWithImage:(UIImage*)imageToStore inFolderWithName:(NSString*)folderName andImageFileName:(NSString*)fileName;
+ (OperationStatus)removeAllFilesFromFolder:(NSString*)folderName;
+ (OperationStatus)removeFolderFromDefaultDocumentDirectory:(NSString*)folderName;
+ (NSArray*)getListOfAllFilesFromFolder:(NSString*)folderName;
+ (OperationStatus)moveFile:(NSString*)fileName fromFolder:(NSString*)sourceFolder toDestinationFolder:(NSString*)destinationFolder;
+ (NSArray*)getListOfAllFolderFromDefaultDirectory;
+ (OperationStatus)removeFile:(NSString*)fileName fromFolder:(NSString*)folderName;
+ (OperationStatus)renameFile:(NSString*)sourceFileName toDestinationFileName:(NSString*)destinationFileName andFolderName:(NSString*)folderName;
+(OperationStatus)renameFolderWithSourceName:(NSString*)sourceFolderName andDestinationFolder:(NSString*)destinationFolderName;

@end
