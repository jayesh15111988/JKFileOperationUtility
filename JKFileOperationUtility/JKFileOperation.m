//
//  JKFileOperation.m
//  JKFileOperationUtility
//
//  Created by Jayesh Kawli Backup on 2/14/15.
//  Copyright (c) 2015 Jayesh Kawli Backup. All rights reserved.
//

#import "JKFileOperation.h"

#if defined(DEBUG) && !defined(DISABLELOG)
#define DLog(xx, ...) NSLog (@"%s(%d): " xx, ((strrchr (__FILE__, '/') ?: __FILE__ - 1) + 1), __LINE__, ##__VA_ARGS__)
#else
#define DLog(xx, ...) ((void)0)
#endif

@interface JKFileOperation ()

@end

@implementation JKFileOperation

+ (NSString *) applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

+ (FolderCreationStatus)createOrCheckForFolderWithName:(NSString*)newFolderName {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    NSString* fullFolderPath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:newFolderName];
    BOOL isDir;
    NSError* error = nil;
    FolderCreationStatus status;
    
    //Also creates nested directory paths like /item1/item2/item3 etc.
    
    if (![fileManager fileExistsAtPath:fullFolderPath isDirectory:&isDir]) {
        if (![fileManager createDirectoryAtPath:fullFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            DLog (@"Error: Create folder failed at path %@ with an Error %@", newFolderName, [error localizedDescription]);
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

+ (void)storeFileWithURL:(NSString*)fileSourceURL inFolderWithName:(NSString*)folderName andImageFileName:(NSString*)imageFileName completion:(void (^)(FileCreationStatus status))completion {
    
    NSString* fullImageFilePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.png", folderName, imageFileName]];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    __block FileCreationStatus status = NewFileCreated;
    BOOL isURLValid = ![self isValueNullOrNil:fileSourceURL];

    if (![fileManager fileExistsAtPath:fullImageFilePath] && isURLValid) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:fileSourceURL]];
            BOOL didFileWriteSucceed = [UIImagePNGRepresentation ([UIImage imageWithData:imageData]) writeToFile:fullImageFilePath atomically:YES];
            status = didFileWriteSucceed ? NewFileCreated : FileDidNotCreateWithError;
            DLog(@"File successfully download and stored in the folder %@", folderName);
            completion(status);
        });

    } else {
        if(!isURLValid) {
            DLog(@"File download operation failed due to invalid URL value %@",fileSourceURL);
            status = FileDidNotCreateWithError;
        } else {
            DLog(@"File with name %@ already exists. New file was not created",imageFileName);
            status = FileExistsDidNotCreateNew;
        }
        completion(status);
    }
}

+ (FileCreationStatus)storeImageWithImage:(UIImage*)imageToStore inFolderWithName:(NSString*)folderName andImageFileName:(NSString*)fileName {
    FileCreationStatus status = NewFileCreated;
    NSString* fullFilePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.png", folderName, fileName]];
    BOOL isDir = false;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:fullFilePath isDirectory:&isDir]) {
        status = FileExistsDidNotCreateNew;
    } else {
        BOOL didFileWriteSucceed = [UIImagePNGRepresentation (imageToStore) writeToFile:fullFilePath atomically:YES];
        status = didFileWriteSucceed ? NewFileCreated : FileDidNotCreateWithError;
    }
    DLog(@"Storing UIImage in the folder %@ with filename %@ successfully completed", folderName, fileName);
    return status;
}

+ (OperationStatus)removeAllFilesFromFolder:(NSString*)folderName {
    
    BOOL isDir;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    OperationStatus status = OperationSuccessful;
    NSString* directory = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:folderName];
    
    DLog(@"Removing all filer from folder %@",folderName);
    if ([fileManager fileExistsAtPath:directory isDirectory:&isDir]) {
        
        NSError* error = nil;
        NSArray* listOfAllFilesInFolder = [self getListOfAllFilesFromFolder:folderName];
    
        for (NSString* filePath in listOfAllFilesInFolder) {
            if ([fileManager fileExistsAtPath:filePath isDirectory:&isDir]) {
                BOOL fileDeletionOperationSuccessfulStatus = [fileManager removeItemAtPath:filePath error:&error];
                if(!fileDeletionOperationSuccessfulStatus) {
                    status = OperationFailed;
                    break;
                } else {
                    DLog(@"File removal operation successded for file %@", [filePath lastPathComponent]);
                }
            }
        }
    } else {
        DLog(@"Files removal operation from folder failed for folder with name %@",folderName);
        status = OperationFailed;
    }
    return status;
}

+ (NSArray*)getListOfAllFilesFromFolder:(NSString*)folderName {
    
    NSString* documentsPath = [self applicationDocumentsDirectory];
    
    NSArray* listOfAllFileNameFromDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[documentsPath stringByAppendingPathComponent:folderName] error:NULL];
    
    NSMutableArray* listOfAllFilesWithDocumentsPathAppended = [NSMutableArray new];
    NSString* updatedFileNameWithDocumentsPath;
    
    for (NSString* individualFileName in listOfAllFileNameFromDirectory) {
        
        updatedFileNameWithDocumentsPath = [NSString stringWithFormat:@"%@/%@/%@", documentsPath, folderName, individualFileName];
        [listOfAllFilesWithDocumentsPathAppended addObject:updatedFileNameWithDocumentsPath];
    }
    DLog(@"Getting list of all files from folder %@", folderName);
    return listOfAllFilesWithDocumentsPathAppended;
}

+ (OperationStatus)removeFolderFromDefaultDocumentDirectory:(NSString*)folderName {
    
    NSError* error = nil;
    NSString* fullFolderPath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:folderName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    OperationStatus status = OperationSuccessful;
    
    //Removes whole directory pattern from system
    if ([fileManager fileExistsAtPath:fullFolderPath]) {
        BOOL folderDeletionOperationSuccessfulStatus = [fileManager removeItemAtPath:fullFolderPath error:&error];
        if(!folderDeletionOperationSuccessfulStatus || error) {
            status = OperationFailed;
        } else {
            DLog(@"Removing file %@ from folder %@", [fullFolderPath lastPathComponent], folderName);
        }
    } else {
        status = OperationFailed;
    }
    return status;
}

+(OperationStatus)moveFile:(NSString*)fileName fromFolder:(NSString*)sourceFolder toDestinationFolder:(NSString*)destinationFolder {
    
    NSString* defaultDocumentDirectory = [self applicationDocumentsDirectory];
    NSString *fromPath=[defaultDocumentDirectory stringByAppendingPathComponent:sourceFolder];
    NSString *toPath = [defaultDocumentDirectory stringByAppendingPathComponent:destinationFolder];
    NSString *sourceFileFullPath = [fromPath stringByAppendingPathComponent:fileName];
    NSString *destinationFileFullPath = [toPath stringByAppendingPathComponent:fileName];
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = false;
    OperationStatus status = OperationSuccessful;
    
    DLog(@"Moving file %@ from folder %@ to folder %@",fileName, sourceFolder, destinationFolder);
    if(![fileManager fileExistsAtPath:sourceFileFullPath isDirectory:&isDir]) {
        status = OperationFailed;
    } else {
        if([fileManager fileExistsAtPath:destinationFileFullPath isDirectory:&isDir]) {
            [fileManager removeItemAtPath:destinationFileFullPath error:&error];
        }
        
        if(![fileManager moveItemAtPath:sourceFileFullPath toPath:destinationFileFullPath error:&error]){
            status = OperationFailed;
        }
    }
    return status;
}

+ (OperationStatus)renameFile:(NSString*)sourceFileName toDestinationFileName:(NSString*)destinationFileName andFolderName:(NSString*)folderName {
    OperationStatus status = OperationSuccessful;
    NSString* defaultDocumentDirectory = [self applicationDocumentsDirectory];
    NSString* sourceFile = [[defaultDocumentDirectory stringByAppendingPathComponent:folderName] stringByAppendingPathComponent:sourceFileName];
    NSString* destinationFile = [[defaultDocumentDirectory stringByAppendingPathComponent:folderName] stringByAppendingPathComponent:destinationFileName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    BOOL isDir = false;
    //Check if file indeed exists
    if([fileManager fileExistsAtPath:sourceFile isDirectory:&isDir]) {
        BOOL fileMoveOperationSuccessful = [fileManager moveItemAtPath:sourceFile toPath:destinationFile error:&error];
        if(!fileMoveOperationSuccessful || error) {
            status = OperationFailed;
        }
    } else {
        status = OperationFailed;
    }
    return status;
}

+ (NSArray*)getListOfAllFolderFromDefaultDirectory {
    DLog(@"Getting list of all folder from default documents directory");
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self applicationDocumentsDirectory] error:nil];
}

+(BOOL)isValueNullOrNil:(NSString*)inputValue {
    return ((inputValue == nil) || (inputValue == (id)[NSNull null]));
}
@end