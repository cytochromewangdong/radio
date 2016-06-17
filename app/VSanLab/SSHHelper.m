//
//  SSHHelper.m
//  VSanLab
//
//  Created by Don Wang on 6/14/16.
//  Copyright © 2016 VMWare. All rights reserved.
//

#import "SSHHelper.h"


@implementation SSHHelper
+(NSString *)executeRemoteShellCommand:(NSString *)command session:(NMSSHSession *)session success:(void (^)(id))success failure:(void (^)(NSError *))failure
{
    
    NSError *error = nil;
    NSString *response = [session.channel execute:command error:&error];
    if(error.code!=0)
    {
        failure(error);
    } else {
        success(response);
    }
//    NSString *response = [session.channel execute:@"ls -l /var/www/" error:&error];
    NSLog(@"List of my sites: %@", response);
    
//    BOOL success = [session.channel uploadFile:@"~/index.html" to:@"/var/www/9muses.se/"];
//    
//    [session disconnect];
    return response;
}
+(NMSSHSession*) openSession:(NSString*)host username:(NSString*) username password:(NSString*)password
{
    NMSSHSession *session = [NMSSHSession connectToHost:host
                                           withUsername:username];
    
    if (session.isConnected) {
        [session authenticateByPassword:password];
        
        if (session.isAuthorized) {
            NSLog(@"Authentication succeeded");
        }
    }
    return session;
}
+(void) closeSession:(NMSSHSession*) session{
    [session disconnect];
}
@end
