//
//  SimpleLoginService.m
//  EastDay
//
//  Created by xiaoxtan on 6/28/14.
//  Copyright (c) 2014 EastDay. All rights reserved.
//

#import "SimpleLoginService.h"
#import "AFNetworking.h"
#import "SimpleRow.h"
#import "SVProgressHUD.h"
#import "NSObject+SBJson.h"
#import "SBJsonWriter.h"
//#define CONST_URL @"http://192.168.1.104:8089"
#define BLOCK_SIZE (250*1024)
#define PROFILE_INFORMATION @"profile"
#define MAX_RETRY_TIMES 3
NSString* newsServer= @"http://192.168.1.104:8089";
static SimpleLoginService* instance;
static NSMutableArray* wrapperArray;
@implementation SimpleLoginService
+(NSString*)syncData
{
    SimpleAllCom *com = [[SimpleAllCom alloc]init];
    NSMutableArray* arrayWithoutStyles=[NSMutableArray new];
    for(SimpleRow* row in wrapperArray)
    {
        if(![[row.name lowercaseString] hasPrefix:@"styles"] && !row.hidden)
        {
           // NSLog(row.name);
            [arrayWithoutStyles addObject:row];
        }
    }
    com.rows = arrayWithoutStyles;
    return [[[SBJsonWriter alloc] init] stringWithObject:com.dataDict];
    //return [com.dataDict JSONRepresentation];
}
+(NSString*)getFileLocation:(NSString*) fileName
{
    NSString* root =[[SimpleLoginService getInstance]getSyncRoot];
    //root =[root stringByAppendingPathComponent:@"jquery-ui-1.11.0.custom"];
    root =[root stringByAppendingPathComponent:fileName];
    return root;
}
+(NSString*)getDataRoot
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [[paths objectAtIndex:0]stringByAppendingPathComponent:@"data"];
    return documentsDirectory;
}
+(NSString *)getDataFullFilePath:(NSString *)file
{
    NSString* root =[self getDataRoot];
    file = [file stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    NSString* newPath = [NSString stringWithFormat:@"%@/%@", root, file];
    return newPath;
}
+(void) saveData:(NSString*) fileName Data:(NSString*)data
{
   NSData *rawData = [data dataUsingEncoding:NSUTF8StringEncoding];
    NSString* fullPath = [self getDataFullFilePath:fileName];
    [rawData writeToFile:fullPath atomically:YES];
}
+(NSString*)getData:(NSString*) fileName
{
    NSString* fullPath = [self getDataFullFilePath:fileName];
    NSString* data = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
    return data;
}
+(void)saveDict:(NSArray*) array
{
    NSMutableArray *newCollection = [[NSMutableArray alloc]init];
    for(SimpleRow *row in array)
    {
        [newCollection addObject:row.dataDict];
    }
    
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:newCollection forKey:@"MAIN_KEY"];
    [archiver finishEncoding];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *newPath = [self getDataFullFilePath:@"ALL"];
    //            [fileManager fileExistsAtPath:newPath];
    NSString* parentPath = [newPath stringByDeletingLastPathComponent];
    [fileManager createDirectoryAtPath:parentPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createFileAtPath:newPath contents:data attributes:nil];
}
+(NSArray*)restoreDict
{
    NSData *data = [[NSMutableData alloc] initWithContentsOfFile:[self getDataFullFilePath:@"ALL"]];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSArray *array = [unarchiver decodeObjectForKey:@"MAIN_KEY"];
    [unarchiver finishDecoding];
    return array;

}
+(void)initialize
{
    instance = [[SimpleLoginService alloc]init];
    wrapperArray = [[NSMutableArray alloc]init];
    NSArray* dataSaved = [self restoreDict];
    for(NSDictionary* dict in dataSaved)
    {
        SimpleRow *wrapperRow = [[SimpleRow alloc]init];
        [wrapperRow setFullNewData:dict];
        wrapperRow.name = wrapperRow.name;
        [wrapperArray addObject:wrapperRow];
    }
}

+(SimpleLoginService*) getInstance
{
    return instance;
}
-(void) fetchXMLData:(NSString*) urlString className:(NSString*)className param:(NSDictionary*)param check:(BOOL (^)(id))check success:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableDictionary* httpParam = [NSMutableDictionary dictionaryWithDictionary:param];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    NSLog(@"request url: %@", [url absoluteString]);
    NSLog(@"httpParam = %@", httpParam);
    
    NSURLRequest *request = [httpClient requestWithMethod:@"GET" path:nil url:url parameters:httpParam];//[NSURLRequest requestWithURLCache:url];
    //     NSURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:nil url:url parameters:httpParam constructingBodyWithBlock:block];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    //    requestOperation.allowsInvalidSSLCertificate = YES;
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSError *error=nil;
        if (operation.response.statusCode == 200){
            NSLog(@"%@",[operation responseData]);
            if(![operation responseData])
            {
                [self showError:@"后台数据为空，请重新尝试！"];
                NSNotification *notification = [NSNotification notificationWithName:FINISH_ACTION object:nil];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
                return;
            }
            NSLog(@"response str: %@", [operation responseString]);
            
            //            NSDictionary *dict =[XMLReader dictionaryForXMLData:[operation responseData] error:&error];
            NSMutableDictionary *dict = [NSJSONSerialization JSONObjectWithData: [operation responseData] options: NSJSONReadingMutableContainers
                                                                          error: &error];
            BaseModel* model = [[NSClassFromString(className) alloc]init];
            model.dataDict = dict;//[dict objectForKey:@"result"];
            model.lastTime =  [[NSDate date] timeIntervalSince1970];
            if(check)
            {
                if(!check(model))
                {
                    [SVProgressHUD dismiss];
                    return;
                }
            }
            if(success)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(model);
                });
            }
        }
        else
        {
            [SVProgressHUD dismiss];
            NSError *error = [[NSError alloc]init];
            [error setValue:[NSNumber numberWithInteger:operation.response.statusCode] forKey:@"ErrorCode"];
            [self showError:@"服务器段错误！"];
            NSNotification *notification = [NSNotification notificationWithName:FINISH_ACTION object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
            failure(error);
            
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        [SVProgressHUD dismiss];
        [self showError:@"网络连接错误！"];
        NSNotification *notification = [NSNotification notificationWithName:FINISH_ACTION object:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        failure(error);
    }];
    
    [requestOperation start];
}
- (void)showError:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"信息"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"关闭"
                                              otherButtonTitles:nil];
    
    [alertView show];
}

-(void)fetchFileList:(void (^)(id))success failure:(void (^)(NSError *)) failure
{
    //    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:phoneNumber,@"phoneNumber",type,@"type", nil];
    NSString* url = [NSString stringWithFormat:@"%@/list",newsServer];
    [self fetchXMLData:url className:@"SimpleAllCom" param:nil check: ^(id model){
        
        return YES;
    } success:success failure:^(NSError *error) {
        if(failure)
        {
            failure(error);
        }
    }];
}

-(NSString*)getSyncRoot
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [[paths objectAtIndex:0]stringByAppendingPathComponent:@"sync"];
    return documentsDirectory;
}
- (NSString *)getFullFilePath:(NSString *)file
{
    NSString* root =[self getSyncRoot];
    file = [file stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    NSString* newPath = [NSString stringWithFormat:@"%@/%@", root, file];
    return newPath;
}

- (NSString *)getTempFilePath:(NSString *)file
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [[paths objectAtIndex:0]stringByAppendingPathComponent:@"temp"];
    file = [file stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
    NSString* newPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
    return newPath;
}

-(void)downloadFile:(SimpleRow*)row mainMonitorOperation:(NSBlockOperation*)mainMonitorOperation QueueManager:(NSOperationQueue*)queque allCollection:(NSMutableArray *)allCollection failCollection:(NSMutableArray *)failCollection  count:(NSInteger)count success:(void (^)(id))success failure:(void (^)(NSError *)) failure
{
    //    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:phoneNumber,@"phoneNumber",type,@"type", nil];
    NSString* urlString = [NSString stringWithFormat:@"%@/list",newsServer];
    NSURL *url = [NSURL URLWithString:urlString];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    NSURLRequest *request = [httpClient requestWithMethod:@"GET" path:nil url:url parameters:@{@"file": row.name}];//[NSURLRequest requestWithURLCache:url];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tempPath = [self getTempFilePath:row.name];
    NSString* parentPath = [tempPath stringByDeletingLastPathComponent];
    [fileManager createDirectoryAtPath:parentPath withIntermediateDirectories:YES attributes:nil error:nil];
    //    [fileManager createFileAtPath:newPath contents:[operation responseData] attributes:nil];
    requestOperation.outputStream = [NSOutputStream outputStreamToFileAtPath:tempPath append:NO];
    
    NSDictionary *userData = @{@"count":[[NSNumber alloc]initWithLong:count]};
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (operation.response.statusCode == 200){
//            NSFileManager *fileManager = [NSFileManager defaultManager];
//            NSString *newPath;
            NSString* newPath = [self getFullFilePath:row.name];
            [fileManager fileExistsAtPath:newPath];
            NSString* parentPath = [newPath stringByDeletingLastPathComponent];
            [fileManager createDirectoryAtPath:parentPath withIntermediateDirectories:YES attributes:nil error:nil];
            [fileManager removeItemAtPath:newPath error:nil];
//            [fileManager createFileAtPath:newPath contents:[operation responseData] attributes:nil];
            [fileManager moveItemAtPath:tempPath  toPath:newPath error:nil];
            NSLog(@"finished download file:%@, %d", newPath, [fileManager fileExistsAtPath:newPath]);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self writebackSatus:row];
            });
 
            // TODO notify
            // TODO save status
            NSNotification *notification = [NSNotification notificationWithName:@"progress" object:userData];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }
        else
        {
//            [fileManager removeItemAtPath:newPath error:nil];
            if(row.downloadCount>MAX_RETRY_TIMES)
            {
                @synchronized(failCollection)
                {
                    [failCollection addObject:row];
                }
                //[SVProgressHUD dismiss];
                NSError *error = [[NSError alloc]init];
                [error setValue:[NSNumber numberWithInteger:operation.response.statusCode] forKey:@"ErrorCode"];
                failure(error);
            } else {
                //                int newCount = retryCount+1;
                row.downloadCount++;
                //                [self downloadFile:row mainMonitorOperation:mainMonitorOperation QueueManager:queque failCollection:failCollection success:success failure:failure];
                @synchronized(allCollection)
                {
                    [allCollection addObject:row];
                }
            }
            
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        [fileManager removeItemAtPath:newPath error:nil];
        if(row.downloadCount>MAX_RETRY_TIMES)
        {
            //[SVProgressHUD dismiss];
            failure(error);
        } else {
            row.downloadCount++;
            
            //            [newCollection addObject:row];
            //            [self downloadFile:row mainMonitorOperation:mainMonitorOperation QueueManager:queque failCollection:failCollection  success:success failure:failure];
            @synchronized(allCollection)
            {
                [allCollection addObject:row];
            }
        }
    }];
    [mainMonitorOperation addDependency:requestOperation];
    [queque addOperation:requestOperation];
    //    [requestOperation start];
    
}
-(void) batchDownload:(NSMutableArray *)newCollection
     failedCollection:(NSMutableArray *)failCollection count:(NSInteger)count
{
    //if([newCollection count])
    NSOperationQueue* queque = [[NSOperationQueue alloc]init];
    queque.maxConcurrentOperationCount = 5;
    NSBlockOperation* finishedOperation = [[NSBlockOperation alloc]init];
    [finishedOperation addExecutionBlock:^{
        if([newCollection count]<=0)
            
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                //TODO
                [SimpleLoginService saveDict:wrapperArray];
                NSLog(@"finished all tasks!");
                //    [[NSUserDefaults standardUserDefaults] synchronize];
                NSDictionary *userData =
                                @{@"failed":failCollection,
                                @"count":[[NSNumber alloc]initWithLong:count]};
                NSNotification *notification = [NSNotification notificationWithName:FINISH_ACTION object:userData];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
            });
        } else {
            [self batchDownload:newCollection failedCollection:failCollection count:count];
        }
    }];
    
    for(int i=0;i<10&&[newCollection count]>0;i++)
    {
        SimpleRow *row = [SimpleRow new];
        @synchronized(newCollection)
        {
            row.dataDict = [newCollection objectAtIndex:0];
            [newCollection removeObjectAtIndex:0];
        }
        [self downloadFile:row mainMonitorOperation:finishedOperation QueueManager:queque allCollection:newCollection  failCollection:failCollection count:count success:nil failure:nil];
        
    }
    [queque addOperation:finishedOperation];
    
}
-(void) writebackSatus:(SimpleRow *) row
{

    NSUInteger index = [wrapperArray indexOfObject:row];
    if(index!=NSNotFound)
    {
        SimpleRow* existedRow = [wrapperArray objectAtIndex:index];
        existedRow.commitedDate = existedRow.date;
    }
}
-(void) syncWithRemoteFileSystem:(BOOL) force
{
    [self fetchFileList:^(id model){
        SimpleAllCom *com = model;
        
//        NSArray* dataSaved = [[NSUserDefaults standardUserDefaults] arrayForKey:PROFILE_INFORMATION];
//        NSMutableArray* wrapperArray = [[NSMutableArray alloc]init];
//        for(NSDictionary* dict in dataSaved)
//        {
//            SimpleRow *wrapperRow = [[SimpleRow alloc]init];
//            [wrapperRow setFullNewData:dict];
//            [wrapperArray addObject:wrapperRow];
//        }
        for(SimpleRow *wrapperRow  in wrapperArray)
        {
            wrapperRow.flag = @0;
        }
        NSMutableArray *newCollection = [[NSMutableArray alloc]init];
        NSMutableArray *fullCollection = [[NSMutableArray alloc]init];
        NSMutableArray *failCollection = [[NSMutableArray alloc]init];
        for(SimpleRow *row in com.rows)
        {
            row.name = [row.name stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
            for(SimpleRow* subrow in row.files)
            {
                subrow.name= [subrow.name stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
            }
            NSUInteger index = [wrapperArray indexOfObject:row];
            if(index!=NSNotFound)
            {
                SimpleRow* existedRow = [wrapperArray objectAtIndex:index];
                if(!existedRow.commitedDate || (existedRow.commitedDate && ![row.date isEqualToNumber:existedRow.commitedDate] ) || force)
                {
                    //                    [self downloadFile:row.name mainMonitorOperation:finishedOperation QueueManager:queque retryCount:0 success:nil failure:nil];
                    [newCollection addObject:existedRow];
                    existedRow.flag = @1;
                }
                [fullCollection addObject:existedRow];
                existedRow.date = row.date;
            } else {
//                SimpleRow *wrapperRow = [[SimpleRow alloc]init];
//                [wrapperRow setFullNewData:dict];
                row.flag = @1;
                [newCollection addObject:row];
                [fullCollection addObject:row];
                //                [self downloadFile:row.name mainMonitorOperation:finishedOperation QueueManager:queque retryCount:0 success:nil failure:nil];
            }
        }
        for(SimpleRow *wrapperRow  in wrapperArray)
        {
            if(![com.rows containsObject:wrapperRow])
            {
                NSString* fullPath = [self getFullFilePath:wrapperRow.name];
                [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
            }
        }
        wrapperArray = fullCollection;
//        [[NSUserDefaults standardUserDefaults] setObject:newCollection forKey:PROFILE_INFORMATION];
        
        
        //        [queque addOperation:finishedOperation];
        [self batchDownload:newCollection failedCollection:failCollection count:[newCollection count]];
    } failure:nil];
    
}
@end
