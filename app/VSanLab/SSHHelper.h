//
//  SSHHelper.h
//  VSanLab
//
//  Created by Don Wang on 6/14/16.
//  Copyright © 2016 VMWare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NMSSHSession.h"

@interface SSHHelper : NSObject

+(NSString*) executeRemoteShellCommand:(NSString*) command session:(NMSSHSession *)session success:(void (^)(id))success failure:(void (^)(NSError *))failure;
+(NMSSHSession*) openSession:(NSString*)host username:(NSString*) username password:(NSString*)password;
+(void) closeSession:(NMSSHSession*) session;
//+(BOOL) uploadFile:()
@end
