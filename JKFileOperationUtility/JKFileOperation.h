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
+ (FileCreationStatus)storeFileWithURL:(NSString*)fileSourceURL inFolderWithName:(NSString*)folderName andImageFileName:(NSString*)imageFileName;
+ (FileCreationStatus)storeImageWithImage:(UIImage*)imageToStore inFolderWithName:(NSString*)folderName andImageFileName:(NSString*)fileName;
+ (OperationStatus)removeAllFilesFromFolder:(NSString*)folderName;
+ (OperationStatus)removeFolderFromDefaultDocumentDirectory:(NSString*)folderName;
+ (NSArray*)getListOfAllFilesFromFolder:(NSString*)folderName;
+ (OperationStatus)moveFile:(NSString*)fileName fromFolder:(NSString*)sourceFolder toDestinationFolder:(NSString*)destinationFolder;
+ (NSArray*)getListOfAllFolderFromDefaultDirectory;

@end
