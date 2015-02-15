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

+ (JKFileOperation*)sharedInstance {
    static dispatch_once_t once;
    static JKFileOperation* sharedInstance;
    
    dispatch_once(&once, ^ {
        sharedInstance = [self new];
        sharedInstance.rootDocumentDirectory = [self applicationDocumentsDirectory];
        sharedInstance.fileManager = [NSFileManager defaultManager];
    });
    
    return sharedInstance;
}

+ (NSString *) applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSString*)escapeName:(NSString*)inputFileName {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z0-9_ !]+" options:0 error:nil];
    return [[regex stringByReplacingMatchesInString:inputFileName options:0 range:NSMakeRange(0, inputFileName.length) withTemplate:@"-"] stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
}

- (FolderCreationStatus)createOrCheckForFolderWithName:(NSString*)newFolderName {
    
    //newFolderName = [self escapeName:newFolderName];
    NSString* fullFolderPath = [self.rootDocumentDirectory stringByAppendingPathComponent:newFolderName];
    BOOL isDir;
    NSError* error = nil;
    FolderCreationStatus status;
    
    //Also creates nested directory paths like /item1/item2/item3 etc.
    if (![self.fileManager fileExistsAtPath:fullFolderPath isDirectory:&isDir]) {
        if (![self.fileManager createDirectoryAtPath:fullFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
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

- (void)storeFileWithURL:(NSString*)fileSourceURL inFolderWithName:(NSString*)folderName andImageFileName:(NSString*)imageFileName completion:(void (^)(FileCreationStatus status))completion {
    
    folderName = [self escapeName:folderName];
    NSString* fullImageFilePath = [self.rootDocumentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.png", folderName, imageFileName]];
    __block FileCreationStatus status = NewFileCreated;
    BOOL isURLValid = ![self isValueNullOrNil:fileSourceURL];

    if (![self.fileManager fileExistsAtPath:fullImageFilePath] && isURLValid) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSData* imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:fileSourceURL]];
            if(imageData != nil) {
                BOOL didFileWriteSucceed = [UIImagePNGRepresentation ([UIImage imageWithData:imageData]) writeToFile:fullImageFilePath atomically:YES];
                status = didFileWriteSucceed ? NewFileCreated : FileDidNotCreateWithError;
                DLog(@"File successfully download and stored in the folder %@", folderName);
            } else {
                status = FileDidNotCreateWithError;
            }
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

- (FileCreationStatus)storeImageWithImage:(UIImage*)imageToStore inFolderWithName:(NSString*)folderName andImageFileName:(NSString*)fileName {
    FileCreationStatus status = NewFileCreated;
    folderName = [self escapeName:folderName];
    NSString* fullFilePath = [self.rootDocumentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@.png", folderName, fileName]];
    BOOL isDir = false;
    if([self.fileManager fileExistsAtPath:fullFilePath isDirectory:&isDir]) {
        status = FileExistsDidNotCreateNew;
    } else {
        BOOL didFileWriteSucceed = [UIImagePNGRepresentation (imageToStore) writeToFile:fullFilePath atomically:YES];
        status = didFileWriteSucceed ? NewFileCreated : FileDidNotCreateWithError;
    }
    DLog(@"Storing UIImage in the folder %@ with filename %@ successfully completed", folderName, fileName);
    return status;
}

- (OperationStatus)removeAllFilesFromFolder:(NSString*)folderName {
    
    BOOL isDir;
    folderName = [self escapeName:folderName];
    OperationStatus status = OperationSuccessful;
    NSString* directory = [self.rootDocumentDirectory stringByAppendingPathComponent:folderName];
    
    DLog(@"Removing all filer from folder %@",folderName);
    if ([self.fileManager fileExistsAtPath:directory isDirectory:&isDir]) {
        
        NSError* error = nil;
        NSArray* listOfAllFilesInFolder = [self getListOfAllFilesFromFolder:folderName];
    
        for (NSString* filePath in listOfAllFilesInFolder) {
            if ([self.fileManager fileExistsAtPath:filePath isDirectory:&isDir]) {
                BOOL fileDeletionOperationSuccessfulStatus = [self.fileManager removeItemAtPath:filePath error:&error];
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

- (OperationStatus)removeFile:(NSString*)fileName fromFolder:(NSString*)folderName {
    OperationStatus status = OperationSuccessful;
    NSString* fullFilePath = [[self.rootDocumentDirectory stringByAppendingPathComponent:folderName] stringByAppendingPathComponent:fileName];
    BOOL isDir = false;
    NSError* error = nil;
    
    if ([self.fileManager fileExistsAtPath:fullFilePath isDirectory:&isDir]) {
        BOOL fileDeletionOperationSuccessfulStatus = [self.fileManager removeItemAtPath:fullFilePath error:&error];
        if(!fileDeletionOperationSuccessfulStatus) {
            status = OperationFailed;
        } else {
            DLog(@"File removal operation succeeded for file %@", [fullFilePath lastPathComponent]);
        }
    } else {
        status = OperationFailed;
    }
    return status;
}

- (NSArray*)getListOfAllFilesFromFolder:(NSString*)folderName {
    
    folderName = [self escapeName:folderName];
    NSArray* listOfAllFileNameFromDirectory = [self.fileManager contentsOfDirectoryAtPath:[self.rootDocumentDirectory stringByAppendingPathComponent:folderName] error:NULL];
    
    NSMutableArray* listOfAllFilesWithDocumentsPathAppended = [NSMutableArray new];
    NSString* updatedFileNameWithDocumentsPath;
    
    for (NSString* individualFileName in listOfAllFileNameFromDirectory) {
        
        updatedFileNameWithDocumentsPath = [NSString stringWithFormat:@"%@/%@/%@", self.rootDocumentDirectory, folderName, individualFileName];
        [listOfAllFilesWithDocumentsPathAppended addObject:updatedFileNameWithDocumentsPath];
    }
    DLog(@"Getting list of all files from folder %@", folderName);
    return listOfAllFilesWithDocumentsPathAppended;
}

- (OperationStatus)removeFolderFromDefaultDocumentDirectory:(NSString*)folderName {
    
    NSError* error = nil;
    folderName = [self escapeName:folderName];
    NSString* fullFolderPath = [self.rootDocumentDirectory stringByAppendingPathComponent:folderName];
    
    OperationStatus status = OperationSuccessful;
    
    //Removes whole directory pattern from system
    if ([self.fileManager fileExistsAtPath:fullFolderPath]) {
        BOOL folderDeletionOperationSuccessfulStatus = [self.fileManager removeItemAtPath:fullFolderPath error:&error];
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

- (OperationStatus)moveFile:(NSString*)fileName fromFolder:(NSString*)sourceFolder toDestinationFolder:(NSString*)destinationFolder {
    
    sourceFolder = [self escapeName:sourceFolder];
    destinationFolder = [self escapeName:destinationFolder];
    
    NSString *fromPath=[self.rootDocumentDirectory stringByAppendingPathComponent:sourceFolder];
    NSString *toPath = [self.rootDocumentDirectory stringByAppendingPathComponent:destinationFolder];
    NSString *sourceFileFullPath = [fromPath stringByAppendingPathComponent:fileName];
    NSString *destinationFileFullPath = [toPath stringByAppendingPathComponent:fileName];
    NSError *error = nil;

    BOOL isDir = false;
    OperationStatus status = OperationSuccessful;
    
    DLog(@"Moving file %@ from folder %@ to folder %@",fileName, sourceFolder, destinationFolder);
    if(![self.fileManager fileExistsAtPath:sourceFileFullPath isDirectory:&isDir] || ![self.fileManager fileExistsAtPath:toPath isDirectory:&isDir]) {
        status = OperationFailed;
    } else {
        if([self.fileManager fileExistsAtPath:destinationFileFullPath isDirectory:&isDir]) {
            [self.fileManager removeItemAtPath:destinationFileFullPath error:&error];
        }
        
        if(![self.fileManager moveItemAtPath:sourceFileFullPath toPath:destinationFileFullPath error:&error]){
            status = OperationFailed;
        }
    }
    return status;
}

- (OperationStatus)renameFile:(NSString*)sourceFileName toDestinationFileName:(NSString*)destinationFileName andFolderName:(NSString*)folderName {
    
    OperationStatus status = OperationSuccessful;
    folderName = [self escapeName:folderName];
    NSString* sourceFile = [[self.rootDocumentDirectory stringByAppendingPathComponent:folderName] stringByAppendingPathComponent:sourceFileName];
    NSString* destinationFile = [[self.rootDocumentDirectory stringByAppendingPathComponent:folderName] stringByAppendingPathComponent:destinationFileName];

    NSError* error = nil;
    BOOL isDir = false;
    //Check if file indeed exists
    if([self.fileManager fileExistsAtPath:sourceFile isDirectory:&isDir]) {
        BOOL fileMoveOperationSuccessful = [self.fileManager moveItemAtPath:sourceFile toPath:destinationFile error:&error];
        if(!fileMoveOperationSuccessful || error) {
            status = OperationFailed;
        }
    } else {
        status = OperationFailed;
    }
    return status;
}

-(OperationStatus)renameFolderWithSourceName:(NSString*)sourceFolderName andDestinationFolder:(NSString*)destinationFolderName {
    OperationStatus status = OperationSuccessful;
    
    sourceFolderName = [self escapeName:sourceFolderName];
    destinationFolderName = [self escapeName:destinationFolderName];
    
    NSString* sourceFolderPath = [self.rootDocumentDirectory stringByAppendingPathComponent:sourceFolderName];
    NSString* destinationFolderPath = [self.rootDocumentDirectory stringByAppendingPathComponent:destinationFolderName];

    NSError* error = nil;
    BOOL isDir = false;
    
    if([self.fileManager fileExistsAtPath:sourceFolderPath isDirectory:&isDir]) {
        BOOL didFolderRenameOperationSuccessful = [self.fileManager moveItemAtPath:sourceFolderPath toPath:destinationFolderPath error:&error];
        if(!didFolderRenameOperationSuccessful || error) {
            status = OperationFailed;
        }
    } else {
        status = OperationFailed;
    }
    return status;
}

- (NSArray*)getListOfAllFolderFromDefaultDirectory {
    DLog(@"Getting list of all folder from default documents directory");
    return [self.fileManager contentsOfDirectoryAtPath:self.rootDocumentDirectory error:nil];
}

- (BOOL)isValueNullOrNil:(NSString*)inputValue {
    return ((inputValue == nil) || (inputValue == (id)[NSNull null]));
}

@end