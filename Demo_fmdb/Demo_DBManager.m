//
//  Demo_DBManager.m
//  Demo_fmdb
//
//  Created by luxiaoming on 16/5/11.
//  Copyright © 2016年 luxiaoming. All rights reserved.
//

#import "Demo_DBManager.h"

@implementation Demo_DBManager

+ (instancetype)sharedDBManager {
    static Demo_DBManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Demo_DBManager alloc] init];
    });
    return sharedInstance;
}

- (void)openDB:(NSString *)dbName {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:dbName];
    
    self.dbQueue = [[FMDatabaseQueue alloc] initWithPath:path];
    
    [self createTable];
    
}




#pragma mark - PrivateMethod

- (void)createTable {
    
    NSString *createFileTableSql = @"CREATE TABLE IF NOT EXISTS Demo_file (fileId INTEGER PRIMARY KEY, name TEXT, localPath TEXT);";
    
    NSString *createUserTableSql = @"CREATE TABLE IF NOT EXISTS Demo_user (userId INTEGER PRIMARY KEY, name TEXT);";
    
    NSString *createUserFileReferenceTableSql = @"CREATE TABLE IF NOT EXISTS Demo_user_file_reference (userId INTEGER, fileId INTEGER, PRIMARY KEY (userId, fileId));";
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:createFileTableSql];
        [db executeUpdate:createUserTableSql];
        [db executeUpdate:createUserFileReferenceTableSql];
    }];
    
}

#pragma mark - PublicMethod

- (void)logAllDBFile {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *sql = @"SELECT * FROM Demo_file;";
        
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            
            FMResultSet *result = [db executeQuery:sql];
            
            while (result.next) {
                NSInteger fileId = [result intForColumn:@"fileId"];
                NSString *name = [result stringForColumn:@"name"];
                NSString *localPath = [result stringForColumn:@"localPath"];
                NSLog(@"file is: %@  %@  %@ ", @(fileId), name, localPath);
            }
            
        }];
        
        
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *sql = @"SELECT * FROM Demo_user;";
        
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            
            FMResultSet *result = [db executeQuery:sql];
            
            while (result.next) {
                NSInteger userId = [result intForColumn:@"userId"];
                NSString *name = [result stringForColumn:@"name"];
                NSLog(@"user is %@ %@", @(userId), name);
            }
            
        }];
        
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *sql = @"SELECT * FROM Demo_user_file_reference;";
        
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            
            FMResultSet *result = [db executeQuery:sql];
            
            while (result.next) {
                NSInteger userId = [result intForColumn:@"userId"];
                NSInteger fileId = [result intForColumn:@"fileId"];
                NSLog(@"result is: (userId %@)   (fileId %@)", @(userId), @(fileId));
            }
            
        }];
        
        
    });
    
    
    
    
}

- (void)saveFileToDB:(Demo_File *)file {
    NSString *sql = @"REPLACE INTO Demo_file (fileId, name, localPath) VALUES (?, ?, ?);";
    NSNumber *fileId = @(file.fileId);
    NSString *name = file.name;
    NSString *localPath = file.localPath;
    
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        if (![db executeUpdate:sql, fileId, name, localPath]) {
            
            *rollback = YES;
            
        }
        
    }];
}

/**
 *  这个方法会同时更新关系表数据
 */
- (void)saveUserToDB:(Demo_User *)user {
    NSString *sql = @"REPLACE INTO Demo_user (userId, name) VALUES (?, ?);";
    NSNumber *courseId = @(user.userId);
    NSString *courseName = user.name;
    
    NSString *addReferenceSql = @"REPLACE INTO Demo_user_file_reference (userId, fileId) VALUES (?, ?)";
    
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        if (![db executeUpdate:sql, courseId, courseName]) {
            
            *rollback = YES;
            
        }
        
        for (NSNumber *fileId in user.fileArray) {
            if (![db executeUpdate:addReferenceSql, courseId, fileId]) {
                
                *rollback = YES;
                
            }
        }
        
    }];
}

- (void)deleteUserFromDBWithUserId:(NSInteger)userId completion:(void(^)(void))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *deleteUserSql = @"DELETE FROM Demo_user WHERE userId = ?;";
        NSString *selectReferenceSql = [NSString stringWithFormat:@"SELECT DISTINCT * FROM Demo_user_file_reference WHERE userId = %@;", @(userId)];
        NSString *deleteReferenceSql = @"DELETE FROM Demo_user_file_reference WHERE userId = ?;";
        
        [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            
            if (![db executeUpdate:deleteUserSql, @(userId)]) {//删除Demo_user表中数据
                
                *rollback = YES;
            }
            
            NSMutableArray *tempArarry = [NSMutableArray array];
            FMResultSet *result = [db executeQuery:selectReferenceSql];//需要检测是否要删除的文件列表
            while (result.next) {
                NSInteger fileId = [result intForColumn:@"fileId"];
                [tempArarry addObject:@(fileId)];
            }
            
            if (![db executeUpdate:deleteReferenceSql, @(userId)]) {//删除Demo_user_file_reference关系表中的关系
                *rollback = YES;
            }
            
            for (NSNumber *number in tempArarry) {
                NSInteger fileId = number.integerValue;
                NSString *selectFileSql = [NSString stringWithFormat:@"SELECT * FROM Demo_file WHERE fileId = %@", @(fileId)];
                FMResultSet *fileResult = [db executeQuery:selectFileSql];//查询出指定文件
                while (fileResult.next) {
//                    NSString *fileLocalPath = [fileResult stringForColumn:@"localPath"];
//                    if (fileLocalPath && fileLocalPath.length > 0) {
                        NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(userId) FROM Demo_user_file_reference WHERE fileId = %@", @(fileId)];
                        NSInteger count = [db intForQuery:sql];//判断该文件是否有其他课程用到
                        if (count == 0) {
                            NSError *deleteFileError = nil;
//                            [[NSFileManager defaultManager] removeItemAtPath:fileLocalPath error:&deleteFileError];
                            if (deleteFileError == nil) {
//                                NSLog(@"delete file at path : %@", fileLocalPath);
                                [db executeUpdate:@"DELETE FROM Demo_file WHERE fileId = ?", @(fileId)];
                            }
                            
                        }
//                    }
                    
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (completion) {
                    completion();
                }
            });
            
        }];
    });
    
    
    
}

- (void)fetchAllFileWithCompletion:(FetchCompletion)completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableArray *resultArray = [NSMutableArray array];

        NSString *sql = @"SELECT * FROM Demo_file;";
        
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            
            FMResultSet *result = [db executeQuery:sql];
            
            while (result.next) {
                Demo_File *file = [[Demo_File alloc] init];
                file.fileId = [result intForColumn:@"fileId"];
                file.name = [result stringForColumn:@"name"];
                file.localPath = [result stringForColumn:@"localPath"];
                [resultArray addObject:file];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(resultArray, nil);
                }
            });
            
        }];
        
        
    });
    
    
}

- (void)fetchAllUserWithCompletion:(FetchCompletion)completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableArray *resultArray = [NSMutableArray array];
        
        NSString *sql = @"SELECT * FROM Demo_user;";
        
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            
            FMResultSet *result = [db executeQuery:sql];
            
            while (result.next) {
                Demo_User *user = [[Demo_User alloc] init];
                user.userId = [result intForColumn:@"userId"];
                user.name = [result stringForColumn:@"name"];
                
                NSMutableArray *fileArray = [NSMutableArray array];
                NSString *fileSql = @"SELECT * FROM Demo_user_file_reference WHERE userId = ?";
                FMResultSet *fileResult = [db executeQuery:fileSql, @(user.userId)];
                while (fileResult.next) {
                    NSInteger fileId = [fileResult intForColumn:@"fileId"];
                    [fileArray addObject:@(fileId)];
                }
                user.fileArray = fileArray;
                [resultArray addObject:user];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(resultArray, nil);
                }
            });
            
        }];
        
    });
}


@end
