//
//  main.m
//  MD5Files
//
//  Created by ryan on 2019/4/13.
//  Copyright © 2019 回响. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

/// 获取md5字符串
NSString* md5(NSString *str) {
    const char *ptr = [str UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x",md5Buffer[i]];
    }
    return output;
}

/// 判断是否是文件夹, 文件存在并且是文件夹返回true，否则返回false
BOOL isDirectory(NSString *filePath) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    BOOL directoryExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    return directoryExists && isDirectory;
}

/// 从文件URL获取文件夹名
NSString* fileDirectoryFromFilePath(NSString *filePath) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:filePath]) {
        return nil;
    }
    NSMutableString *fileDirectory = [NSMutableString stringWithString:filePath];
    NSString *fileName = fileDirectory.lastPathComponent;
    NSRange range = [fileDirectory rangeOfString:fileName options:NSBackwardsSearch];
    [fileDirectory deleteCharactersInRange:range];
    return fileDirectory;
}


/// 从文件URL获取文件名
NSString* filenameFromFileURL(NSURL* fileURL) {
    return fileURL.lastPathComponent;
}

NSString* fileNameFromFilePath(NSString *filePath) {
    return filenameFromFileURL([NSURL fileURLWithPath:filePath]);
}


/**
 以MD5的形式重新命名文件

 @param fileURL 源文件路径
 @param md5Name 重命名后的文件名
 @return 重命名成功返回true,否则返回false
 */
BOOL renameFileMD5(NSURL *fileURL, NSString **md5Name) {
    NSString *directory = fileDirectoryFromFilePath(fileURL.path);
    if(directory == nil) {
        return false;
    }
    NSString *fileName = fileURL.lastPathComponent;
    NSString *md5FileName = md5(fileName);
    *md5Name = md5FileName;
    NSString *md5FilePath = [NSString stringWithFormat:@"%@%@", directory, md5FileName];
    NSURL *md5FileURL = [NSURL fileURLWithPath:md5FilePath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager moveItemAtURL:fileURL toURL:md5FileURL error:&error];
    return error == nil;
}

BOOL renameFileMD5WithPath(NSString *filePath, NSString **md5Name) {
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    return renameFileMD5(fileURL, md5Name);
}

/// 所有文件以md5的形式命名
void md5AllFiles(NSString* folderPath, NSMutableArray *symbolTable) {
    NSLog(@"symbolTable: %@", symbolTable);
    BOOL isDir = isDirectory(folderPath);
    
    if(!isDir) {
        NSString *fileName = fileNameFromFilePath(folderPath);
        NSString *md5Name;
        renameFileMD5WithPath(folderPath, &md5Name);
        [symbolTable addObject:@{fileName: md5Name}];
        return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:folderPath error:nil];
    [fileNames enumerateObjectsUsingBlock:^(NSString  *fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", folderPath, fileName];
        if(isDirectory(filePath)) {
            md5AllFiles(filePath, symbolTable);
        } else {
            NSString *md5Name;
            renameFileMD5WithPath(filePath, &md5Name);
            [symbolTable addObject:@{fileName: md5Name}];
        }
    }];
}

/// 列出所有的文件
NSDictionary* enumAllFiles(NSString* folderPath) {
    NSMutableDictionary *folders = [NSMutableDictionary dictionary];
    BOOL isDir = isDirectory(folderPath);
    if(!isDir) {
        return nil;
    }
    NSMutableArray *files = [NSMutableArray array];
    folders[folderPath] = files;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:folderPath error:nil];
    [fileNames enumerateObjectsUsingBlock:^(NSString  *fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", folderPath, fileName];
        
        if(isDirectory(filePath)) {
            folders[filePath] = enumAllFiles(filePath);
        } else {
            [files addObject:filePath];
        }
    }];
    return folders;
}

/**
 删除文件夹下所有重复的文件

 @param folderPath 文件夹路径
 @param files <#files description#>
 */
void deleteSameFile(NSString* folderPath, NSMutableArray *files) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:folderPath error:nil];
    [fileNames enumerateObjectsUsingBlock:^(NSString  *fileName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", folderPath, fileName];
        if(isDirectory(filePath)) {
            NSLog(@"遍历文件夹：%@", folderPath);
            deleteSameFile(filePath, files);
        } else {
            if([files containsObject:fileName]) {
                [fileManager removeItemAtPath:filePath error:nil];
                NSLog(@"删除%@", filePath);
                return;
            }
            NSLog(@"新增文件：%@", filePath);
            [files addObject:fileName];
        }
    }];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *filePath = @"/Users/bbb/Desktop/h52/static/img/0a127555c6b5e8cb2597736da10079da";
        NSString *fileDirectory = @"/Users/bbb/Desktop/h52/static/img";
        NSLog(@"文件夹为： %@", fileDirectoryFromFilePath(filePath));
        NSLog(@"文件夹为： %@", fileDirectoryFromFilePath(fileDirectory));
//        renameFileMD5([NSURL fileURLWithPath:fileDirectory]);
//        NSString *fileDirectory2 = @"/Users/bbb/Desktop/h5/static";
//        NSDictionary *allFiles = enumAllFiles(fileDirectory2);
//        NSLog(@"%@", allFiles);
        NSMutableArray *symbolTable =  [NSMutableArray array];
        md5AllFiles(fileDirectory, symbolTable);
        [symbolTable writeToFile:[NSString stringWithFormat:@"%@/%@", fileDirectory, @"symbol.txt"] atomically:true];
        NSMutableArray *allFiles = [NSMutableArray array];
        deleteSameFile(fileDirectory, [NSMutableArray array]);
        NSLog(@"%@", allFiles);
    }
    return 0;
}


