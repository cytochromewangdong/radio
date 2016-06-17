//
//  BaseModel.h
//  ExampleApp
//
//  Created by wang dong on 4/13/14.
//  Copyright (c) 2014 Thong Nguyen. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const cModalClassNameKey;
@interface BaseModel : NSObject
{
    NSMutableDictionary *_dataDict;
}

@property (strong)NSString* id;
@property (assign)NSTimeInterval lastTime;
@property (assign)int page;
@property(nonatomic, strong)NSMutableDictionary *dataDict;
-(void)setFullNewData:(NSDictionary*)newData;
-(void)setInt:(int)value forKey:(NSString *)key;
-(void)setObject:(id)value forKey:(NSString *)key;

-(int)intForKey:(NSString *)key;
-(id)objectForKey:(NSString *)key;
-(NSData*) toJson;
-(BOOL) isExpired;
+(id)modelFromData:(NSData*)data;

@end