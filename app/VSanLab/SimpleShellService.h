//
//  SimpleShellService.h
//  VSanLab
//
//  Created by Don Wang on 6/14/16.
//  Copyright © 2016 VMWare. All rights reserved.
//

#import <Foundation/Foundation.h>
#define PROGRESS_ACTION @"progress"
#define FINISH_ACTION @"finished"
#define ERROR @"error"
@interface SimpleShellService : NSObject
+(NSString*)getSyncRoot;
+(void)deleteRoot;
+(NSString*)getFileLocation:(NSString*) fileName;
-(id)initWithLogin:(NSString*)server username:(NSString*)username password:(NSString*)password;
-(void) syncWithRemoteFileSystem:(NSString*) path;
-(BOOL) isvalid;
-(NSDictionary*)executeShellReturnJson:(NSString*) command failure:(void (^)(NSError *))failure;
@end
