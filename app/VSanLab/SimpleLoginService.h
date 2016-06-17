//
//  SimpleLoginService.h
//  EastDay
//
//  Created by xiaoxtan on 6/28/14.
//  Copyright (c) 2014 EastDay. All rights reserved.
//

#import <Foundation/Foundation.h>
extern NSString* newsServer;
#define PROGRESS_ACTION @"progress"
#define FINISH_ACTION @"finished"
@interface SimpleLoginService : NSObject
+(NSString*)syncData;
+(NSString*)getData:(NSString*) fileName;
+(NSString*)getFileLocation:(NSString*) fileName;
+(void) saveData:(NSString*) fileName Data:(NSString*)data;
+(SimpleLoginService*) getInstance;
-(NSString*)getSyncRoot;
//-(void)fetchFileList:(void (^)(id))success failure:(void (^)(NSError *)) failure;
-(void) syncWithRemoteFileSystem:(BOOL) force;
@end
