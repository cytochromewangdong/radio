/*!
 * \file    WebViewController
 * \project
 * \author  Andy Rifken
 * \date    11/20/12.
 *
 * Copyright 2012 Andy Rifken
 
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



#import "RootViewController.h"
#import "JavascriptBridgeURLCache.h"
#import "NativeAction.h"
//#import "SimpleLoginService.h"
#import "SimpleShellService.h"
#import <AddressBook/AddressBook.h>
#import "SSHHelper.h"


@implementation RootViewController
@synthesize webView = mWebView;

+ (void)initialize {
    [super initialize];
    
    // Create an instance of our custom NSURLCache object to use for
    // to check any outgoing requests in our app
    JavascriptBridgeURLCache *cache = [[JavascriptBridgeURLCache alloc] init];
    [NSURLCache setSharedURLCache:cache];
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
-(NSString*) indexFile
{
    NSString* root =[SimpleShellService getSyncRoot];
    //root =[root stringByAppendingPathComponent:@"jquery-ui-1.11.0.custom"];
    root =[root stringByAppendingPathComponent:@"index.html"];
    return root;
}
- (void)openIndex
{
    //    id internalWebView=[[self.webView _documentView] webView];
    //    [internalWebView setMaintainsBackForwardList:NO];
    //    [internalWebView setMaintainsBackForwardList:YES];
    
    NSString* root = [self indexFile];
    NSURL *nsUrl = [NSURL fileURLWithPath:root];
    NSURLRequest *request  = [NSURLRequest requestWithURL:nsUrl];
    //       [NSURLRequest requestWithURL:nsUrl];
    NSLog(@"url is %@",nsUrl);
    //[self.webView stringByEvaluatingJavaScriptFromString:@"finished()"];
    [self.webView loadRequest:request];
    
}

-(void)onFinish:(NSNotification *)note
{
    id userInfo = note.object;
    NSString *jsfun = [NSString stringWithFormat:@"progress(-1)"];
    [self.webView stringByEvaluatingJavaScriptFromString:jsfun];
    [self openIndex];
    
    //    self.webView loadRequest:<#(NSURLRequest *)#>
}
-(void)onProgress:(NSNotification *)note
{
    NSDictionary* userInfo = note.object;
    NSString *jsfun = [NSString stringWithFormat:@"progress(%@)", [userInfo objectForKey:@"count"]];
    [self.webView stringByEvaluatingJavaScriptFromString:jsfun];
}
-(void)error:(NSNotification *)note
{
    
    [self.webView stringByEvaluatingJavaScriptFromString:@"error()"];
}
- (void)openSync {
    // load our HTML and JS from a local file
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"sync" ofType:@"html"];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    [mWebView loadRequest:[NSURLRequest requestWithURL:url]];
}
-(void) ongesture
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

-(void) buttonClicked:(UIButton*)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self openSync];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // create our webview and add it to the view hierarchy
    CGRect rect = self.view.bounds;
    rect.size.height = rect.size.height;
    mWebView = [[UIWebView alloc] initWithFrame:rect];//
    mWebView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    mWebView.scrollView.bounces = NO;
    //mWebView.autoresizingMask = UIViewAutoresizingNone;
    [mWebView setBackgroundColor:[UIColor whiteColor]];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self
               action:@selector(buttonClicked:)
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Sync" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.backgroundColor = [UIColor lightGrayColor];
    button.layer.borderColor = [UIColor blackColor].CGColor;
    button.layer.borderWidth = 0.5f;
    button.layer.cornerRadius = 10.0f;
    button.frame = CGRectMake(rect.size.width/2 - 80, rect.size.height - 60, 160.0, 40.0);
    
    
    
    [self.view addSubview:mWebView];
    
    [self.view addSubview:button];
    
    if(self.docURL)
    {
        mWebView.scalesPageToFit = YES;
        mWebView.delegate = self;
        NSURL *url = [[NSURL alloc]initFileURLWithPath:self.docURL];
        [mWebView loadRequest:[NSURLRequest requestWithURL:url]];
        
        UISwipeGestureRecognizer *mSwipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(ongesture)];
        
        [mSwipeUpRecognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
        
        [[self view] addGestureRecognizer:mSwipeUpRecognizer];
    } else {
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:[self indexFile]];
        if(fileExists)
        {
            [self openIndex];
        } else {
            [self openSync];
        }
        // Tell our custom NSURLCache object that we want this class to handle requests to native code. This method
        // is a category on NSURLCache that safely sets the delegate property (defined in JavascriptBridgeURLCache.h)
        [NSURLCache setJavascriptBridgeDelegate:self];
        //    [[SimpleLoginService getInstance]fetchFileList:nil failure:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFinish:) name:FINISH_ACTION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProgress:) name:PROGRESS_ACTION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(error:) name:ERROR object:nil];
    }
    //    [[SimpleLoginService getInstance] syncWithRemoteFileSystem:NO success:nil];
    
}

- (void)dealloc {
    // This instance is going away, so unbind it from our custom NSURLCache
    // [NSURLCache setJavascriptBridgeDelegate:nil];
}

#pragma mark -
#pragma mark WebView Delegate
//============================================================================================================


/*!
 * This is the method that gets called when Javascript wants to tell our native app something. It is called from our
 * shared JavascriptBridgeURLCache object.
 *
 * \param nativeAction The request from Javascript
 * \param error A pointer to an error object that we can populate if we encounter a problem in handling this request
 * \return A dictionary that will be serialized into a JSON object and sent back to Javascript as the response
 */
- (BOOL) fullhandleAction:(NativeAction *)action
{
    if ([action.action isEqualToString:@"sync"]) {
        
        [SimpleShellService deleteRoot];
        
        NSString* server = [action.params objectForKey:@"url"];
        NSString* username = [action.params objectForKey:@"username"];
        NSString* password = [action.params objectForKey:@"password"];
        NSString* path = [action.params objectForKey:@"path"];
        SimpleShellService* shellService = [[SimpleShellService alloc]initWithLogin:server username:username password:password];
        if([shellService isvalid])
        {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [shellService syncWithRemoteFileSystem:path];
            });
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
        }
        return YES;
    } else if ([action.action isEqualToString:@"opensync"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self openSync];
        });
        return YES;
    }else if ([action.action isEqualToString:@"index"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self openIndex];
        });
        return YES;
    } else if([action.action isEqualToString:@"open"])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString* fileName = [action.params objectForKey:@"fileName"];
            RootViewController* rootView = [[RootViewController alloc] init];
            rootView.docURL = [SimpleShellService getFileLocation:fileName];//[NSURL fileURLWithPath:[SimpleLoginService getFileLocation:fileName]];
            [self presentViewController:rootView animated:YES
                             completion:^{}];
        });
        return YES;
    } else if([action.action isEqualToString:@"sendmail"])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([MFMailComposeViewController canSendMail])
            {
                MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
                controller.mailComposeDelegate = self;
                [controller setSubject:[action.params objectForKey:@"subject"]];
                [controller setMessageBody:[action.params objectForKey:@"body"] isHTML:NO];
                [self presentViewController:controller animated:YES completion:^{}];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"信息"
                                                                    message:@"发送邮件之前，请设置邮箱！"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"关闭"
                                                          otherButtonTitles:nil];
                
                [alertView show];
            }
        });
    }
    return NO;
}
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"It's away!");
    }
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (NSDictionary *)handleAction:(NativeAction *)nativeAction error:(NSError **)error {
    // For this demo, we'll handle two types of requests. The first will simply show a native UIAlertView with params
    // passed from Javascript, and the second will go fetch the contacts from our address book and pass names and phone
    // numbers back to Javascript.
    
    // -------- GET /alert
    if ([nativeAction.action isEqualToString:@"alert"]) {
        //Typically, this request is sent to native code on the Web Thread, so if we want to do something that is
        // going to draw to the screen from native code, we need to run it on the main thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[nativeAction.params objectForKey:@"title"] message:[nativeAction.params objectForKey:@"message"] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alertView show];
        });
        return nil;
    }
    
    // -------- GET /contacts
    else if ([nativeAction.action isEqualToString:@"contacts"]) {
        //        // dictionary to store names and phone numbers from the address book
        
        return @{
                 @"contacts" : @{@"wangdong":@"13512183612",@"test":@"189898"}
                 };
    }
    
    return nil;
}


@end