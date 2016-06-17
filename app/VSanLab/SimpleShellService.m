//
//  SimpleShellService.m
//  VSanLab
//
//  Created by Don Wang on 6/14/16.
//  Copyright © 2016 VMWare. All rights reserved.
//

#import "SimpleShellService.h"
#import "SSHHelper.h"
#import "SimpleRow.h"
#import "SVProgressHUD.h"
#define MAX_RETRY_TIMES 3

@interface SimpleShellService()
{
    NMSSHSession* session;
    
}
@end
@implementation SimpleShellService
+(NSString*)getFileLocation:(NSString*) fileName
{
    NSString* root =[SimpleShellService getSyncRoot];
    //root =[root stringByAppendingPathComponent:@"jquery-ui-1.11.0.custom"];
    root =[root stringByAppendingPathComponent:fileName];
    return root;
}

//NMSSHSession* session = [SSHHelper openSession:@"10.160.247.150" username:@"root" password:@"vmware"];
//NSString* result = [SSHHelper executeRemoteShellCommand:@"ls -l ~" session:session];
//NSLog(@"============= %@",result );
-(BOOL) isvalid
{
    return session.isAuthorized;
}
-(id)initWithLogin:(NSString*)server username:(NSString*)username password:(NSString*)password
{
    self = [super init];
    if(self)
    {
        session = [SSHHelper openSession:server username:username  password:password];
    }
    return self;
}

-(void)dealloc {
    [SSHHelper closeSession:session];
}

-(NSString*) executeShellCommand:(NSString*) command success:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    
    return [SSHHelper executeRemoteShellCommand:command session:session success:success failure:failure];
    
}
-(NSDictionary*)executeShellReturnJson:(NSString*) command failure:(void (^)(NSError *))failure
{
    NSError *error = nil;
    NSString *response = [session.channel execute:command error:&error];
    if(error.code!=0)
    {
        failure(error);
    }
    //    NSString *response = [session.channel execute:@"ls -l /var/www/" error:&error];
    NSLog(@"List of my sites: %@", response);
    NSMutableDictionary* result = [NSMutableDictionary new];
    [result setValue:[NSNumber numberWithInteger:error.code] forKey:@"result"];
    [result setValue:response forKey:@"data"];
    return result;
}

-(void)fetchFileList:(NSString*)path success:(void (^)(id))success failure:(void (^)(NSError *)) failure
{
    
    NSMutableArray* collector = [NSMutableArray new];
    NSError* hasError = nil;
    [self recurseFetchFileList:path collector:collector hasError:&hasError];
    if(!hasError)
    {
        success(collector);
    }
    else
    {
        //        NSError *error = [[NSError alloc]initWithDomain:@"Application" code:-1 userInfo:nil];
        
        //[error setValue:forKey:@"ErrorCode"];
        failure(hasError);
    }
    
}
-(NSString*) getFullFilepathPart:(NSString*)fileInfo
{
    NSArray* array = [self sperateString:fileInfo];
    return array.lastObject;
}
-(NSArray*)getValidLines:(NSString*)str
{
    NSArray *brokenByLines=[str componentsSeparatedByString:@"\n"];
    NSMutableArray* lines = [NSMutableArray new];
    for(NSString* line in brokenByLines)
    {
        if([line length]>0)
        {
            [lines addObject:line];
        }
    }
    return lines;
}
-(void)recurseFetchFileList:(NSString*)path collector:(NSMutableArray*)collector hasError:(NSError**) hasError
{
    //NSString* result = [SSHHelper executeRemoteShellCommand:@"ls -l ~" session:session];
    //NSLog(@"============= %@",result );
    //ls -ld $PWD/**|grep ^d
    if (![path hasSuffix:@"/"]){
        path = [NSString stringWithFormat:@"%@/",path];
    }
    
    NSString* filesCommand = [NSString stringWithFormat:@"ls -l %@|grep ^-",path];
    [self executeShellCommand:filesCommand success:^(id res) {
        if([res length]>0){
            NSArray *brokenByLines=[self getValidLines:res];
            for(NSString* fileInfoRow in brokenByLines )
            {
                [collector addObject:[NSString stringWithFormat:@"%@%@",path,[self getFullFilepathPart:fileInfoRow]]];
            }
        }
        
    } failure:^(NSError *error) {
        //        *hasError = YES;
        *hasError = error;
    }];
    
    NSString* dirCommand = [NSString stringWithFormat:@"ls -l %@|grep ^d",path];
    [self executeShellCommand:dirCommand success:^(id res) {
        if([res length]>0){
            NSArray *brokenByLines=[self getValidLines:res];
            for(NSString* fileInfoRow in brokenByLines )
            {
                [self recurseFetchFileList:[NSString stringWithFormat:@"%@%@",path,[self getFullFilepathPart:fileInfoRow]] collector:collector hasError:hasError];
            }
        }
        
    } failure:^(NSError *error) {
        *hasError = error;
    }];
    
    
    
    
}

-(NSArray*)sperateString:(NSString*)aString
{
    NSArray *array = [aString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
    return array;
}
- (void)showError:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Information"
                                                        message:[NSString stringWithFormat:@"There is error: %@", message]
                                                       delegate:nil
                                              cancelButtonTitle:@"Close"
                                              otherButtonTitles:nil];
    
    [alertView show];
}
-(void) syncWithRemoteFileSystem:(NSString*) path
{
    [self fetchFileList:path success:^(id model)
     {
         NSMutableArray* wrapperArray = [NSMutableArray new];
         if([model count]>0) {
             for(NSString *name in model)
             {
                 SimpleRow* row  = [SimpleRow new];
                 [wrapperArray addObject:row];
                 row.name = name;
             }
             [self batchDownload:wrapperArray path:path];
         } else {
             [self showError:@"The folder does not contain andy data!"];
             NSDictionary *userData =@{};
             NSNotification *notification = [NSNotification notificationWithName:ERROR object:userData];
             [[NSNotificationCenter defaultCenter] postNotification:notification];
         }
         
     } failure:^(NSError *err) {
         [self showError:err.description];
         NSDictionary *userData =@{};
         NSNotification *notification = [NSNotification notificationWithName:ERROR object:userData];
         [[NSNotificationCenter defaultCenter] postNotification:notification];
     }];
    
}

- (NSString *)getTempFilePath:(NSString *)file path:(NSString*)path
{
    
    file = [file substringFromIndex:path.length];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [[paths objectAtIndex:0]stringByAppendingPathComponent:@"temp"];
    file = [file stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    NSString* newPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
    return newPath;
}

+(NSString*)getSyncRoot
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [[paths objectAtIndex:0]stringByAppendingPathComponent:@"sync"];
    return documentsDirectory;
}
+(void)deleteRoot
{
    NSString* root =[SimpleShellService getSyncRoot];
    
    NSFileManager* fm = [[NSFileManager alloc] init];
    NSDirectoryEnumerator* en = [fm enumeratorAtPath:root];
    NSError* err = nil;
    BOOL res;
    
    NSString* file;
    while (file = [en nextObject]) {
        res = [fm removeItemAtPath:[root stringByAppendingPathComponent:file] error:&err];
        if (!res && err) {
            NSLog(@"oops: %@", err);
        }
    }
}

- (NSString *)getFullFilePath:(NSString *)file path:(NSString*)path
{
    file = [file substringFromIndex:path.length];
    NSString* root =[SimpleShellService getSyncRoot];
    file = [file stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    NSString* newPath = [NSString stringWithFormat:@"%@/%@", root, file];
    return newPath;
}

-(BOOL)downloadFile:(SimpleRow*)row path:(NSString*)path success:(void (^)(id))success failure:(void (^)(NSError *)) failure
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tempPath = [self getTempFilePath:row.name path:path];
    NSString* parentPath = [tempPath stringByDeletingLastPathComponent];
    [fileManager createDirectoryAtPath:parentPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    //    NSDictionary *userData = @{@"count":[[NSNumber alloc]initWithLong:count]};
    while(row.downloadCount<MAX_RETRY_TIMES)
    {
        
        if([session.channel downloadFile:row.name to:tempPath])
        {
            NSString* newPath = [self getFullFilePath:row.name path:path];
            [fileManager fileExistsAtPath:newPath];
            NSString* parentPath = [newPath stringByDeletingLastPathComponent];
            [fileManager createDirectoryAtPath:parentPath withIntermediateDirectories:YES attributes:nil error:nil];
            [fileManager removeItemAtPath:newPath error:nil];
            //            [fileManager createFileAtPath:newPath contents:[operation responseData] attributes:nil];
            [fileManager moveItemAtPath:tempPath  toPath:newPath error:nil];
            NSLog(@"finished download file:%@, %d", newPath, [fileManager fileExistsAtPath:newPath]);
            
            return YES;
        }
        else
        {
            //            [fileManager removeItemAtPath:newPath error:nil];
            if(row.downloadCount>MAX_RETRY_TIMES)
            {
                
                //[SVProgressHUD dismiss];
                NSError *error = [[NSError alloc]initWithDomain:@"Application" code:-1 userInfo:nil];
                //                [error setValue:[NSNumber numberWithInteger:-1] forKey:@"ErrorCode"];
                failure(error);
            } else {
                //                int newCount = retryCount+1;
                row.downloadCount++;
            }
            
        }
    }
    
    return NO;
    
    
}
-(void) batchDownload:(NSMutableArray *)newCollection path:(NSString*)path
{
    //if([newCollection count])
    NSOperationQueue* queque = [[NSOperationQueue alloc]init];
    queque.maxConcurrentOperationCount = 1;
    NSBlockOperation* finishedOperation = [[NSBlockOperation alloc]init];
    [finishedOperation addExecutionBlock:^{
        NSInteger failedCount = 0;
        NSInteger processedCount = 0;
        for(SimpleRow *row in newCollection)
        {
            
            [self downloadFile:row path:path success:nil failure:nil];
            processedCount++;
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *userData =  @{@"count":[[NSNumber alloc]initWithLong:newCollection.count]};
                NSNotification *notification = [NSNotification notificationWithName:@"progress" object:userData];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            NSLog(@"finished all tasks!");
            //    [[NSUserDefaults standardUserDefaults] synchronize];
            NSDictionary *userData =
            @{@"failedcount":[[NSNumber alloc]initWithLong:failedCount]};
            NSNotification *notification = [NSNotification notificationWithName:FINISH_ACTION object:userData];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        });
        
    }];
    
    
    [queque addOperation:finishedOperation];
    
}


@end
