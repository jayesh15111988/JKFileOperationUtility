#JKFileOperationUtility
###File operation class in Objective-C to simplify file operation in iOS development 

Since I have been working on one of the projects that required quite bit of caching and storing files in the persistent storage, file operation was quite a headache. Especially with that all complicated and long documents directory name, appending names to it made it painful as project grew in size.

This was the time when I though it's moment to write a library to do this stuff for me. Not surprisingly, I used this library in my next project and whoaaa, the task which took few hours earlier was finished in lass than half n hour with the simple API provided by this library.

I wrote this pod in anticipation that it will help someone else down the road as it did to me. 

##How to add library to the project.

* Download library from https://github.com/jayesh15111988/JKFileOperationUtility and manually add it to your current project by dragging in *.xcodeproj file. This is kind of way I wouldn't recommend you to follow. Better way is to automatically add relevant project files in the working directory through Cocoapods.
* Just add following line to your podfile and run pod install / pod update whether you are running it for the first time or not respectively

`` pod 'JKFileOperationUtility', 
:git => 'git@github.com:jayesh15111988/JKFileOperationUtility.git' , :branch => 'master'
``

And that's it. You are ready to use JKFileOperationUtility in your respective project. That wasn't hard at all! Was it?

##Basic functionalities offered by JKFileOperationUtility are as follows : 
* ``+ (FolderCreationStatus)createOrCheckForFolderWithName:(NSString*)newFolderName;``

>Creates a new folder with name 'newFolderName' in the default documents directory. If folder already exists, it does nothing. This method will create hierarchical folder system too. Like you specify series of folders like folder1/folder2/folder3, this method will still work. 
Following method is used to get path to default documents directory internally : 

```
+ (NSString *) applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,    NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

```

* ```+ (void)storeFileWithURL:(NSString*)fileSourceURL inFolderWithName:(NSString*)folderName andImageFileName:(NSString*)imageFileName  completion:(void (^)(FileCreationStatus status))completion; ```

>Used to download file with given URL and store it in the path specified. In the current version it assumes all files being downloaded have .png extension. In the future version, I will change it to allow user to pass any arbitrary extension while storing this file. You must specify which folder you want to save this file in. To maintain structure and organization, we will assign folder to each and every downloaded file. If you are not dealing with multiple folder structure, just create single default folder and perform all operations on it. But you must have at least one folder inside default directory.

It is important to note that this API is purposely block based to cope up with heavy network operation. File download and storage operation works on the background thread not to interfere with UI activities. Upon completion, if you are updating an UI, you must execute it on main thread with following block. (This is also demonstrated in the demo project)
```
dispatch_async(dispatch_get_main_queue(), ^(void) {
    //UI Update on main thread
});
```

* ```+ (FileCreationStatus)storeImageWithImage:(UIImage*)imageToStore inFolderWithName:(NSString*)folderName andImageFileName:(NSString*)fileName;```

>Similar to the one just above. However, instead of downloading file from remote URL, it will take UIImage as a parameter and convert it into local image file. All images are stored in .png format to preserve alpha value if present at all.

* ```+ (OperationStatus)removeAllFilesFromFolder:(NSString*)folderName; ```

>As name of the method suggests, it will remove all files which are children of 'folderName'. This is irreversible, so please be cautious while using it. If folder does not exist, it will do nothing.
Also, if it encounters any error while deleting files from specified folder, delete operation will interrupt and leave folder with only partially deleted files.

* ```+ (OperationStatus)removeFolderFromDefaultDocumentDirectory:(NSString*)folderName; ```
 
>It is very similar to previous method. Only difference is files vs. documents. It will remove all documents which are children of root/default directory which is obtained by the method specified in the first point.

* ```+ (NSArray*)getListOfAllFilesFromFolder:(NSString*)folderName; ```

>Gives list of all files present in the specified folder. All files are presented with names and does not include their full path. If you wish to obtain full path, first get full path to default document directory and then append folder name and file name to it.

* ```+ (OperationStatus)moveFile:(NSString*)fileName fromFolder:(NSString*)sourceFolder toDestinationFolder:(NSString*)destinationFolder; ```

>Moved file from source folder to the destination folder. If destination folder does not exist, this method will do nothing keeping files in source folder unmoved.

* ```+ (NSArray*)getListOfAllFolderFromDefaultDirectory; ```
 
> This method gives list of all folders which fall under default root directory.

* ```+ (OperationStatus)removeFile:(NSString*)fileName fromFolder:(NSString*)folderName; ```

>Removes file with name 'fileName' from folder 'folderName'. 

* ```+ (OperationStatus)renameFile:(NSString*)sourceFileName toDestinationFileName:(NSString*)destinationFileName andFolderName:(NSString*)folderName; ```

>Renames a file present in given folder from sourceFileName to the destinationFileName

* ```+(OperationStatus)renameFolderWithSourceName:(NSString*)sourceFolderName andDestinationFolder:(NSString*)destinationFolderName; ```

>Renames a folder from sourceFolderName to the destinationFolderName

#Extra Tips : 
* ###Logging
> Application makes use of several NSLog() statements as a part of debugging process. Logging is enabled is debug  and disabled in release builds by default. However, if you wish to disable it in the debug mode just add 'DISABLELOG=1' to Preprocessor Macros in the Build Settings. (_This option needs to be added only for debug configuration_)

* ###Error Reporting
> Application yet does not support extensive error reporting. However, there are certain enums which are used to measure the level of success in file/folders operations.

**For Folder creation there are three states which are indicated by following enums :**
 * NewFolderCreated - New folder successfully created
 * FolderDidNotCreateWithError - Folder was not created due to unknown error
 * FolderExistsDidNotCreateNew - Folder already exists. Was not re-created.

**Similarly for file operations :**
* NewFileCreated - New file successfully created
* FileDidNotCreateWithError - File creation failed with an unknown error
* FileExistsDidNotCreateNew - File already exists. Was not re-created

**Enums for general operations are as follows :**
* OperationSuccessful - Operation was successful
* OperationFailed - Operation Failed
* OperationNotRequired - Operation not required. This can happen when folder/file already exists in the given path

As it is clear from API documentation, method after completing operation sends back respective enums to show the status of requested operation. User can then take actions based on the output value of returned enum.

When you clone a project, you can see a demo application bundled with it which demonstrates almost all functionalities exposed by an API. 

I am working on improving this library for better logging and error reporting support. In the meantime, if you find any bugs or looking for more features to it, don't forget to drop me an email or mention it in comments section.

##Credits : 
This demo was not possible without some of the awesome libraries I had to use in this project. However, pod itself does not have any external dependencies. All dependencies used are utilized for the demo project : 

 - [Reactive Cocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) - **Awesome library to convert code in terms of signal and streams**
 - [SWTableViewCell](https://github.com/CEWendel/SWTableViewCell) - **Provided support to add multiple options for committing edits for tableViewCell.** (_Apparently iOS8 supports this option too, but could not get enough documentation help to do it using official resource._)



