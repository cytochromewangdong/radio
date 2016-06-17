/*!
 * \file    JavascriptBridgeURLCache
 * \project
 * \author  Andy Rifken
 * \date    11/20/12.
 
 Copyright 2012 Andy Rifken
 
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "JavascriptBridgeURLCache.h"
#import "GTMNSDictionary+URLArguments.h"
#import "NativeAction.h"
#import "SBJsonWriter.h"
//#import "SimpleLoginService.h"
#import "SimpleShellService.h"
#import <MessageUI/MFMailComposeViewController.h>

// We'll intercept all requests going to the following host:
const NSString *kAppHost = @"localcall";

@implementation JavascriptBridgeURLCache

@synthesize delegate = mDelegate;

//- (NSCachedURLResponse *)createJSONResponse:(NSData *)json request:(NSURLRequest *)request {

    //    NSString *jsonString = [[[SBJsonWriter alloc] init] stringWithObject:result];
    //    NSData *jsonBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    //    NSURLResponse *res = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"application/json" expectedContentLength:[jsonBody length] textEncodingName:nil];
    //    cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:res data:jsonBody];
    
//    NSCachedURLResponse *cachedResponse= nil;
    //    NSData *jsonBody = [json dataUsingEncoding:NSUTF8StringEncoding];
//    NSURLResponse *res = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"application/json" expectedContentLength:[json length] textEncodingName:nil];
//    NSMutableDictionary* header = [NSMutableDictionary new];
//    [header setValue: @"application/json" forKey:@"content-type"];
//    [header setValue:[[NSNumber numberWithInteger:json.length]stringValue]  forKey:@"content-length"];
////    cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:res data:json];
//    
//    return [self createErrorResponse:200 data:json request:request header:header];
//}
- (NSCachedURLResponse *)createJSONResponse:(NSString *)json request:(NSURLRequest *)request {
    
    //    NSString *jsonString = [[[SBJsonWriter alloc] init] stringWithObject:result];
    //    NSData *jsonBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    //    NSURLResponse *res = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"application/json" expectedContentLength:[jsonBody length] textEncodingName:nil];
    //    cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:res data:jsonBody];
    
//    NSCachedURLResponse *cachedResponse= nil;
    NSData *jsonBody = [json dataUsingEncoding:NSUTF8StringEncoding];
//    NSURLResponse *res = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"application/json" expectedContentLength:[jsonBody length] textEncodingName:nil];
//    cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:res data:jsonBody];
//    return cachedResponse;
   return [self createJSONResponseWithData:jsonBody request:request];
}

- (NSCachedURLResponse *)createJSONResponseWithData:(NSData *)jsonData request:(NSURLRequest *)request {
    
    //    NSString *jsonString = [[[SBJsonWriter alloc] init] stringWithObject:result];
    //    NSData *jsonBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    //    NSURLResponse *res = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"application/json" expectedContentLength:[jsonBody length] textEncodingName:nil];
    //    cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:res data:jsonBody];
    
    NSCachedURLResponse *cachedResponse= nil;
    NSURLResponse *res = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"text/plain" expectedContentLength:[jsonData length] textEncodingName:nil];
    cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:res data:jsonData];
    return cachedResponse;
//        return  [self createErrorResponse:200 data:jsonData request:request header:nil];
}

/*!
 * This method is called by the system before an NSURLRequest goes out. It gives us a chance to intercept an outgoing
 * HTTP request and provide a "cached" response. Typically, this is used to reduce bandwidth usage and unneccessary
 * network transactions, but here we're going to use it to respond to the request as if our native code was the web
 * server.
 */
- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    
    NSURL *url = [request URL];
    
    // check the host to see if Javascript is trying to send a request to our app's "fake" host
    if ([[url host] caseInsensitiveCompare:(NSString *) kAppHost] == NSOrderedSame) {
        
        NSString *action = nil;
        if ([[url pathComponents] count] > 1) { // use index 1 since index 0 is the '/'
            // Theoretically, we could use the :controller/:action/:id pattern here, but for simplicity we'll just do
            // /:action
            action = [[url pathComponents] objectAtIndex:1];
        }
        NSString *query = [url query];
        NSString *method = [request HTTPMethod];
        NSDictionary *params = nil;
        
        // we also want to extract any arguments passed in the request. In a GET, we can get these from the URL query
        // string. In requests with entities, we can get this from the request body (assume www-form encoded for our purposes
        // here, but we could also handle JSON entities)
        NSString *body = nil;
        if ([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"]) {
            body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
            //params = [NSDictionary gtm_dictionaryWithHttpArgumentsString:query];
        } //else
        if([query length]==0)
        {
            params = [NSDictionary gtm_dictionaryWithHttpArgumentsString:body];
        } else {
            params = [NSDictionary gtm_dictionaryWithHttpArgumentsString:query];
            if([[params objectForKey:@"body"]boolValue])
            {
                params = [NSDictionary gtm_dictionaryWithHttpArgumentsString:body];
            }
        }
        // construct a NativeAction object to transport this request message to our handler in native code
        NativeAction *nativeAction = [[NativeAction alloc] initWithAction:action method:method params:params];
        if([self.delegate fullhandleAction:nativeAction])
        {
            return nil;
        }
        //        NSError *error1 = nil;
        //        NSMutableDictionary *result = [[self.delegate handleAction:nativeAction error:&error1] mutableCopy];
        //
        //        // if we got an error, assign it in the hash we'll pass back to javascript
        //        if (error1) {
        //            [result setObject:@{
        //            @"code" : [NSNumber numberWithInt:error1.code],
        //            @"message" : [error1 localizedDescription]
        //
        //            }          forKey:@"error"];
        //        }
        
        // Lastly, we need to construct an NSCachedURLResponse object to return from this method. This is the response
        // (headers + body) that will be passed back to our jQuery callback
        NSCachedURLResponse *cachedResponse = nil;
        NSString* fileName = [nativeAction.params objectForKey:@"fileName"];
        //        if([nativeAction.action isEqualToString:@"filedata"])
        //        {
        //            NSString* json = [SimpleLoginService syncData];
        //            //json =@"{'test':123}";
        //            cachedResponse = [self createJSONResponse:json request:request];
        //
        //        }
        //        else if([nativeAction.action isEqualToString:@"savedata"])
        //        {
        //            [SimpleLoginService saveData:fileName Data:body];
        //
        //        } else if([nativeAction.action isEqualToString:@"getdata"])
        //        {
        //            NSString* json = [SimpleLoginService getData:fileName];
        //            cachedResponse = [self createJSONResponse:json request:request];
        //        } else
      if([nativeAction.action isEqualToString:@"filedata"])
       {
        //            NSString* json = [SimpleLoginService syncData];
            NSString* json =@"{'test':123}";
                NSData *jsonBody = [json dataUsingEncoding:NSUTF8StringEncoding];
                 cachedResponse = [self createJSONResponseWithData:jsonBody request:request];
           return cachedResponse;
         }
        if([nativeAction.action isEqualToString:@"doshell"])
        {
            NSString* server = [nativeAction.params objectForKey:@"url"];
            NSString* username = [nativeAction.params objectForKey:@"username"];
            NSString* password = [nativeAction.params objectForKey:@"password"];
            NSString* cmd = [nativeAction.params objectForKey:@"cmd"];
            SimpleShellService* shellService = [[SimpleShellService alloc]initWithLogin:server username:username password:password];
            if([shellService isvalid])
            {
                if (cmd.length>0)
                {
                    NSDictionary* result= [shellService executeShellReturnJson:cmd failure:nil];
                    NSData* json = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil];
                    cachedResponse = [self createJSONResponseWithData:json request:request];
                } else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Information"
                                                                            message:@"Bad Parameters, shell command can't be empty."
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"Close"
                                                                  otherButtonTitles:nil];
                        
                        [alertView show];
                    });
       
                    cachedResponse = [self createErrorResponse:401 request:request];
                    
                }
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Information"
                                                                        message:@"Can't connect to the SSH server with the username/password, please make sure they are right."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Close"
                                                              otherButtonTitles:nil];
                    
                    [alertView show];
                });
                cachedResponse = [self createErrorResponse:500 request:request];
            }
            
        }
        
        return cachedResponse;
    }
    
    // if not matching our custom host, allow system to handle it
    return [super cachedResponseForRequest:request];
}
- (NSCachedURLResponse *) createErrorResponse:(NSInteger)errorCode  request:(NSURLRequest *)request
{
    NSMutableDictionary* result= [NSMutableDictionary new];
    [result setValue:[NSNumber numberWithInteger:errorCode ] forKey:@"status"];
    NSData* json = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil];
    
    return [self createJSONResponseWithData:json request:request];
}

//- (NSCachedURLResponse *)createTextResponse:(NSString *)text request:(NSURLRequest *)request {
//
//    //    NSString *jsonString = [[[SBJsonWriter alloc] init] stringWithObject:result];
//    //    NSData *jsonBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//    //    NSURLResponse *res = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"application/json" expectedContentLength:[jsonBody length] textEncodingName:nil];
//    //    cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:res data:jsonBody];
//
//    NSCachedURLResponse *cachedResponse= nil;
//    NSData *body = [text dataUsingEncoding:NSUTF8StringEncoding];
//    NSURLResponse *res = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"text/plain" expectedContentLength:[body length] textEncodingName:nil];
//    cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:res data:body];
//
////    [NSHTTPURLResponse alloc]initWithURL:<#(nonnull NSURL *)#> statusCode:<#(NSInteger)#> HTTPVersion:<#(nullable NSString *)#> headerFields:<#(nullable NSDictionary<NSString *,NSString *> *)#>
//    return cachedResponse;
//}
//- (NSCachedURLResponse *) createErrorResponse:(NSInteger)errorCode  request:(NSURLRequest *)request
//{
//    return [self createErrorResponse:errorCode data:nil request:request header:nil];
////}
- (NSCachedURLResponse *) createErrorResponse:(NSInteger)errorCode data:(NSData*)data request:(NSURLRequest *)request header:(NSDictionary*)header {
//    NSCachedURLResponse *cachedResponse= nil;
//    NSHTTPURLResponse* response =  [[NSHTTPURLResponse alloc]initWithURL:request.URL statusCode:errorCode HTTPVersion:@"1.1" headerFields:header];//header
//    NSDictionary *headers = @{@"Access-Control-Allow-Origin" : @"*", @"Access-Control-Allow-Headers" : @"Content-Type"};

    NSHTTPURLResponse *urlresponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:header];
    NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:urlresponse data:data];
    
//    cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
    return cachedResponse;
}
@end


@implementation NSURLCache (JavascriptBridge)

+ (id <JavascriptBridgeDelegate>)javascriptBridgeDelegate {
    NSURLCache *sharedURLCache = [NSURLCache sharedURLCache];
    if ([sharedURLCache isKindOfClass:[JavascriptBridgeURLCache class]]) {
        return [(JavascriptBridgeURLCache *) sharedURLCache delegate];
    }
    return nil;
}

+ (void)setJavascriptBridgeDelegate:(id <JavascriptBridgeDelegate>)delegate {
    NSURLCache *sharedURLCache = [NSURLCache sharedURLCache];
    if ([sharedURLCache isKindOfClass:[JavascriptBridgeURLCache class]]) {
        [(JavascriptBridgeURLCache *) sharedURLCache setDelegate:delegate];
    }
}

@end