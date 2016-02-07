//
//  JKFileOperation.m
//  JKFileOperationUtility
//
//  Created by Jayesh Kawli Backup on 2/14/15.
//  Copyright (c) 2015 Jayesh Kawli Backup. All rights reserved.
//

#import "JKFileOperation.h"
#import "NSString+DecodeString.h"
#import <BlocksKit/NSArray+BlocksKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

#if defined(DEBUG) && !defined(DISABLELOG)
#define DLog(xx, ...) NSLog (@"%s(%d): " xx, ((strrchr (__FILE__, '/') ?: __FILE__ - 1) + 1), __LINE__, ##__VA_ARGS__)
#else
#define DLog(xx, ...) ((void)0)
#endif

@interface JKFileOperation ()

@end

@implementation JKFileOperation

+ (NSString*)applicationDocumentsDirectory {
    NSArray* paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

+ (NSString*)escapeName:(NSString*)inputFileName {
    NSRegularExpression* regex =
        [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z0-9_ .!]+" options:0 error:nil];
    return [[regex stringByReplacingMatchesInString:inputFileName
                                            options:0
                                              range:NSMakeRange (0, inputFileName.length)
                                       withTemplate:@"-"] stringByReplacingOccurrencesOfString:@"/"
                                                                                    withString:@"-"];
}

+ (FolderCreationStatus)createOrCheckForFolderWithName:(NSString*)newFolderName {
    NSFileManager* fileManager = [NSFileManager defaultManager];

    NSString* fullFolderPath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:newFolderName];
    BOOL isDir;
    NSError* error = nil;
    FolderCreationStatus status;

    // Also creates nested directory paths like /item1/item2/item3 etc.
    if (![fileManager fileExistsAtPath:fullFolderPath isDirectory:&isDir]) {
        if (![fileManager createDirectoryAtPath:fullFolderPath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&error]) {
            DLog (@"Error: Create folder failed at path %@ with an Error %@", newFolderName,
                  [error localizedDescription]);
            status = FolderDidNotCreateWithError;
        } else {
            DLog (@"Success: Folder created successfully at path %@", newFolderName);
            status = NewFolderCreated;
        }
    } else {
        DLog (@"Folder Already exists at specified path. Did not take any action");
        status = FolderExistsDidNotCreateNew;
    }

    return status;
}

+ (void)storeFileWithURL:(NSString*)fileSourceURL
        inFolderWithName:(NSString*)folderName
        andImageFileName:(NSString*)imageFileName
              completion:(void (^) (FileCreationStatus status))completion {

    imageFileName = [self escapeName:imageFileName];
    NSString* fullImageFilePath = [[self applicationDocumentsDirectory]
        stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.png", folderName, imageFileName]];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    __block FileCreationStatus status = NewFileCreated;
    BOOL isURLValid = ![self isValueNullOrNil:fileSourceURL];

    if (![fileManager fileExistsAtPath:fullImageFilePath] && isURLValid) {
        dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
          NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:fileSourceURL]];
          if (imageData != nil) {
              BOOL didFileWriteSucceed =
                  [UIImagePNGRepresentation ([UIImage imageWithData:imageData]) writeToFile:fullImageFilePath
                                                                                 atomically:YES];
              status = didFileWriteSucceed ? NewFileCreated : FileDidNotCreateWithError;
              DLog (@"File successfully download and stored in the folder %@", folderName);
          } else {
              status = FileDidNotCreateWithError;
          }
          completion (status);
        });

    } else {
        if (!isURLValid) {
            DLog (@"File download operation failed due to invalid URL value %@", fileSourceURL);
            status = FileDidNotCreateWithError;
        } else {
            DLog (@"File with name %@ already exists. New file was not created", imageFileName);
            status = FileExistsDidNotCreateNew;
        }
        completion (status);
    }
}

+ (FileCreationStatus)storeImageWithImage:(UIImage*)imageToStore
                         inFolderWithName:(NSString*)folderName
                         andImageFileName:(NSString*)fileName {
    FileCreationStatus status = NewFileCreated;
    NSString* fullFilePath = [[self applicationDocumentsDirectory]
        stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.png", folderName, fileName]];
    BOOL isDir = false;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:fullFilePath isDirectory:&isDir]) {
        status = FileExistsDidNotCreateNew;
    } else {
        BOOL didFileWriteSucceed = [UIImagePNGRepresentation (imageToStore) writeToFile:fullFilePath atomically:YES];
        status = didFileWriteSucceed ? NewFileCreated : FileDidNotCreateWithError;
    }
    DLog (@"Storing UIImage in the folder %@ with filename %@ successfully completed", folderName, fileName);
    return status;
}

+ (OperationStatus)removeAllFilesFromFolder:(NSString*)folderName {

    BOOL isDir;
    // folderName = [self escapeName:folderName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    OperationStatus status = OperationSuccessful;
    NSString* directory = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:folderName];

    DLog (@"Removing all filer from folder %@", folderName);
    if ([fileManager fileExistsAtPath:directory isDirectory:&isDir]) {

        NSError* error = nil;
        NSArray* listOfAllFilesInFolder = [self getListOfAllFilesFromBaseFolder:folderName];

        for (NSString* filePath in listOfAllFilesInFolder) {
            if ([fileManager fileExistsAtPath:filePath isDirectory:&isDir]) {
                BOOL fileDeletionOperationSuccessfulStatus = [fileManager removeItemAtPath:filePath error:&error];
                if (!fileDeletionOperationSuccessfulStatus) {
                    status = OperationFailed;
                    break;
                } else {
                    DLog (@"File removal operation successded for file %@", [filePath lastPathComponent]);
                }
            }
        }
    } else {
        DLog (@"Files removal operation from folder failed for folder with name %@", folderName);
        status = OperationFailed;
    }
    return status;
}

+ (OperationStatus)removeFile:(NSString*)fileName fromFolder:(NSString*)folderPath {
    OperationStatus status = OperationSuccessful;
    // fileName = [self escapeName:fileName];
    NSString* fullFilePath = folderPath; //[[[self applicationDocumentsDirectory]
    // stringByAppendingPathComponent:folderName]
    // stringByAppendingPathComponent:fileName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isDir = false;
    NSError* error = nil;

    if ([fileManager fileExistsAtPath:fullFilePath isDirectory:&isDir]) {
        BOOL fileDeletionOperationSuccessfulStatus = [fileManager removeItemAtPath:fullFilePath error:&error];
        if (!fileDeletionOperationSuccessfulStatus) {
            status = OperationFailed;
        } else {
            DLog (@"File removal operation succeeded for file %@", [fullFilePath lastPathComponent]);
        }
    } else {
        status = OperationFailed;
    }
    return status;
}

+ (NSArray*)getListOfAllFilesFromBaseFolder:(NSString*)folderName {

    NSString* fullFolderPath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:folderName];
    NSArray* listOfAllFileNameFromDirectory =
        [[[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:fullFolderPath]
                                       includingPropertiesForKeys:[NSArray arrayWithObject:NSURLNameKey]
                                                          options:NSDirectoryEnumerationSkipsHiddenFiles
                                                            error:nil] bk_map:^id (NSURL* fullFilePathURL) {
          NSString* filePathString = [[fullFilePathURL absoluteString] decodeString];
          if (filePathString.length > 7) {
              filePathString = [filePathString substringWithRange:NSMakeRange (7, [filePathString length] - 7)];
          }
          return filePathString;
        }];

    NSMutableArray* listOfAllFilesWithDocumentsPathAppended = [NSMutableArray new];

    for (NSString* individualPathString in listOfAllFileNameFromDirectory) {
        [listOfAllFilesWithDocumentsPathAppended addObject:individualPathString];
    }
    DLog (@"Getting list of all files from folder %@", folderName);
    return listOfAllFilesWithDocumentsPathAppended;
}

+ (OperationStatus)removeFolderFromDefaultDocumentDirectory:(NSString*)folderPath {

    NSError* error = nil;
    NSString* fullFolderPath = folderPath;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    OperationStatus status = OperationSuccessful;

    // Removes whole directory pattern from system
    if ([fileManager fileExistsAtPath:fullFolderPath]) {
        BOOL folderDeletionOperationSuccessfulStatus = [fileManager removeItemAtPath:fullFolderPath error:&error];
        if (!folderDeletionOperationSuccessfulStatus || error) {
            status = OperationFailed;
        }
    } else {
        status = OperationFailed;
    }
    return status;
}

+ (OperationStatus)moveFile:(NSString*)fileName
                 fromFolder:(NSString*)sourceFolder
        toDestinationFolder:(NSString*)destinationFolder {

    // sourceFolder = [self escapeName:sourceFolder];
    // destinationFolder = [self escapeName:destinationFolder];
    fileName = [self escapeName:fileName];

    NSString* defaultDocumentDirectory = [self applicationDocumentsDirectory];
    NSString* fromPath = [defaultDocumentDirectory stringByAppendingPathComponent:sourceFolder];
    NSString* toPath = [defaultDocumentDirectory stringByAppendingPathComponent:destinationFolder];
    NSString* sourceFileFullPath = [fromPath stringByAppendingPathComponent:fileName];
    NSString* destinationFileFullPath = [toPath stringByAppendingPathComponent:fileName];
    NSError* error = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL isDir = false;
    OperationStatus status = OperationSuccessful;

    DLog (@"Moving file %@ from folder %@ to folder %@", fileName, sourceFolder, destinationFolder);
    if (![fileManager fileExistsAtPath:sourceFileFullPath isDirectory:&isDir] ||
        ![fileManager fileExistsAtPath:toPath isDirectory:&isDir]) {
        status = OperationFailed;
    } else {
        if ([fileManager fileExistsAtPath:destinationFileFullPath isDirectory:&isDir]) {
            [fileManager removeItemAtPath:destinationFileFullPath error:&error];
        }

        if (![fileManager moveItemAtPath:sourceFileFullPath toPath:destinationFileFullPath error:&error]) {
            status = OperationFailed;
        }
    }
    return status;
}

+ (OperationStatus)renameFile:(NSString*)sourceFileName
        toDestinationFileName:(NSString*)destinationFileName
                andFolderName:(NSString*)folderName {

    OperationStatus status = OperationSuccessful;
    // folderName = [self escapeName:folderName];
    sourceFileName = [self escapeName:sourceFileName];
    destinationFileName = [self escapeName:destinationFileName];

    NSString* defaultDocumentDirectory = [self applicationDocumentsDirectory];
    NSString* sourceFile = [[defaultDocumentDirectory stringByAppendingPathComponent:folderName]
        stringByAppendingPathComponent:sourceFileName];
    NSString* destinationFile = [[defaultDocumentDirectory stringByAppendingPathComponent:folderName]
        stringByAppendingPathComponent:destinationFileName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    BOOL isDir = false;
    // Check if file indeed exists
    if ([fileManager fileExistsAtPath:sourceFile isDirectory:&isDir]) {
        BOOL fileMoveOperationSuccessful = [fileManager moveItemAtPath:sourceFile toPath:destinationFile error:&error];
        if (!fileMoveOperationSuccessful || error) {
            status = OperationFailed;
        }
    } else {
        status = OperationFailed;
    }
    return status;
}

+ (OperationStatus)renameFolderWithSourceName:(NSString*)sourceFolderName
                         andDestinationFolder:(NSString*)destinationFolderName {
    OperationStatus status = OperationSuccessful;

    // sourceFolderName = [self escapeName:sourceFolderName];
    // destinationFolderName = [self escapeName:destinationFolderName];

    NSString* rootDirectoryPath = [self applicationDocumentsDirectory];
    NSString* sourceFolderPath = [rootDirectoryPath stringByAppendingPathComponent:sourceFolderName];
    NSString* destinationFolderPath = [rootDirectoryPath stringByAppendingPathComponent:destinationFolderName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    BOOL isDir = false;

    if ([fileManager fileExistsAtPath:sourceFolderPath isDirectory:&isDir]) {
        BOOL didFolderRenameOperationSuccessful =
            [fileManager moveItemAtPath:sourceFolderPath toPath:destinationFolderPath error:&error];
        if (!didFolderRenameOperationSuccessful || error) {
            status = OperationFailed;
        }
    } else {
        status = OperationFailed;
    }
    return status;
}

+ (FileType)fileTypeAtPath:(NSString*)fullPath {

    BOOL isDirectory;
    BOOL fileExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
    if (fileExistsAtPath) {
        if (isDirectory) {
            return FileTypeDirectory;
        } else {
            CFStringRef fileExtension = (__bridge CFStringRef)[fullPath pathExtension];
            CFStringRef fileUTI =
                UTTypeCreatePreferredIdentifierForTag (kUTTagClassFilenameExtension, fileExtension, NULL);
            if (UTTypeConformsTo (fileUTI, kUTTypeImage)) {
                return FileTypeImage;
            } else if (UTTypeConformsTo (fileUTI, kUTTypeMovie)) {
                return FileTypeVideo;
            }
        }
    }
    return FileTypeUnknown;
}

+ (UIImage*)imageAtPath:(NSString*)fullImagePath {
    BOOL isDirectory;
    BOOL fileExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:fullImagePath isDirectory:&isDirectory];
    if (fileExistsAtPath) {
        NSData* imageData = [NSData dataWithContentsOfFile:fullImagePath];
        return [[UIImage alloc] initWithData:imageData];
    }
    return nil;
}

+ (NSArray*)getListOfAllFilesFromBaseFolder {
    DLog (@"Getting list of all folder from default documents directory");
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self applicationDocumentsDirectory] error:nil];
}

+ (BOOL)isValueNullOrNil:(NSString*)inputValue {
    return ((inputValue == nil) || (inputValue == (id)[NSNull null]));
}

@end