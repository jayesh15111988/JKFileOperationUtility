//
//  JKFileOperation.h
//  JKFileOperationUtility
//
//  Created by Jayesh Kawli Backup on 2/14/15.
//  Copyright (c) 2015 Jayesh Kawli Backup. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM (NSUInteger, FolderCreationStatus) {
    NewFolderCreated,
    FolderDidNotCreateWithError,
    FolderExistsDidNotCreateNew
};

typedef NS_ENUM (NSUInteger, FileCreationStatus) {
    NewFileCreated,
    FileDidNotCreateWithError,
    FileExistsDidNotCreateNew
};

typedef NS_ENUM (NSUInteger, OperationStatus) { OperationSuccessful, OperationFailed, OperationNotRequired };

typedef NS_ENUM (NSUInteger, FileType) { FileTypeDirectory, FileTypeImage, FileTypeVideo, FileTypeUnknown };

@interface JKFileOperation : NSObject

+ (NSString*)applicationDocumentsDirectory;
+ (FolderCreationStatus)createOrCheckForFolderWithName:(NSString*)newFolderName;
// We will make it block based API, as downloading images from remote URL can take longer time and need to run that
// operation on background thread
+ (FileType)fileTypeAtPath:(NSString*)fullPath;
+ (void)storeFileWithURL:(NSString*)fileSourceURL
        inFolderWithName:(NSString*)folderName
        andImageFileName:(NSString*)imageFileName
              completion:(void (^) (FileCreationStatus status))completion;
+ (FileCreationStatus)storeImageWithImage:(UIImage*)imageToStore
                         inFolderWithName:(NSString*)folderName
                         andImageFileName:(NSString*)fileName;
+ (OperationStatus)removeAllFilesFromFolder:(NSString*)folderName;
+ (OperationStatus)removeFolderFromDefaultDocumentDirectory:(NSString*)folderPath;
+ (NSArray*)getListOfAllFilesFromBaseFolder:(NSString*)folderName;
+ (OperationStatus)moveFile:(NSString*)fileName
                 fromFolder:(NSString*)sourceFolder
        toDestinationFolder:(NSString*)destinationFolder;
+ (OperationStatus)removeFile:(NSString*)fileName fromFolder:(NSString*)folderName;
+ (OperationStatus)renameFile:(NSString*)sourceFileName
        toDestinationFileName:(NSString*)destinationFileName
                andFolderName:(NSString*)folderName;
+ (OperationStatus)renameFolderWithSourceName:(NSString*)sourceFolderName
                         andDestinationFolder:(NSString*)destinationFolderName;
+ (UIImage*)imageAtPath:(NSString*)fullImagePath;
+ (NSString*)escapeName:(NSString*)inputFileName;

@end
