//
//  Demo_DBManager.h
//  Demo_fmdb
//
//  Created by luxiaoming on 16/5/11.
//  Copyright © 2016年 luxiaoming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB.h>
#import "Demo_File.h"
#import "Demo_User.h"

typedef void(^FetchCompletion)(NSArray *resultArray, NSError *error);


@interface Demo_DBManager : NSObject

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

+ (instancetype)sharedDBManager;

- (void)openDB:(NSString *)dbName;

- (void)logAllDBFile;

- (void)saveFileToDB:(Demo_File *)file;

/**
 *  这个方法会同时更新关系表数据
 */
- (void)saveUserToDB:(Demo_User *)user;

- (void)deleteUserFromDBWithUserId:(NSInteger)userId completion:(void(^)(void))completion;


- (void)fetchAllFileWithCompletion:(FetchCompletion)completion;

- (void)fetchAllUserWithCompletion:(FetchCompletion)completion;


@end
