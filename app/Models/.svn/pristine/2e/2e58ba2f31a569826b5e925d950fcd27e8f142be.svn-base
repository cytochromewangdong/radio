//
//  BaseModel.m
//  ExampleApp
//
//  Created by wang dong on 4/13/14.
//  Copyright (c) 2014 Thong Nguyen. All rights reserved.
//

#import "BaseModel.h"
 NSString *const cModalClassNameKey=@"$$className";

@implementation BaseModel
-(void)setFullNewData:(NSDictionary*)newData
{
    self.dataDict = [NSMutableDictionary dictionaryWithDictionary:newData];
}
@synthesize dataDict = _dataDict;

-(id)init
{
    self = [super init];
    if (self) {
        _dataDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}
-(int)page
{
    return [self intForKey:@"$$page"];
}
-(void)setPage:(int)page
{
    [self setInt:page forKey:@"$$page"];
}
-(BOOL)succeed
{
    NSLog(@"ret: %@", self);
    return YES;
}

-(void)setInt:(int)value forKey:(NSString *)key
{
    [_dataDict setObject:[NSNumber numberWithInt:value] forKey:key];
}
-(void)setObject:(id)value forKey:(NSString *)key
{
    [_dataDict setObject:value forKey:key];
}

-(int)intForKey:(NSString *)key
{
    NSNumber *number = [_dataDict valueForKey:key];
    return number? [number intValue] : -1;
}

-(id)objectForKey:(NSString *)key
{
    return [_dataDict valueForKey:key];
}

@dynamic id;
-(NSString*) id
{
    return [self.dataDict valueForKey:@"id"];
}
-(void) setId:(NSString*) paramId
{
    [self.dataDict setValue: paramId forKey:@"id"];
}
-(NSData*)toJson
{
   NSString* className = NSStringFromClass([self class]);
    NSError *error=nil;
   [[self dataDict] setValue:className forKey:cModalClassNameKey];
    if (self.dataDict) {
        return [NSJSONSerialization dataWithJSONObject:self.dataDict options:NSJSONWritingPrettyPrinted error:&error];
    } else {
        return nil;
    }
   
    
}
-(NSTimeInterval)lastTime
{
        return [[self.dataDict valueForKey:@"lastTime"]doubleValue];
}
-(void)setLastTime:(NSTimeInterval)lastTime
{
       [_dataDict setObject:[NSNumber numberWithDouble:lastTime] forKey:@"lastTime"];
}
-(BOOL)isExpired
{
    NSTimeInterval timeInMiliseconds = [[NSDate date] timeIntervalSince1970];
    return timeInMiliseconds - self.lastTime>10*60;
}
+(id)modelFromData:(NSData*)data
{
    if(!data) return nil;
//
    NSError *error=nil;
    NSDictionary* dictionary =[NSJSONSerialization
     JSONObjectWithData:data options:NSJSONReadingMutableContainers
     error:&error];
    NSString* className =[dictionary valueForKey:cModalClassNameKey];
    BaseModel* model = [[NSClassFromString(className) alloc]init];
    model.dataDict = (NSMutableDictionary*)dictionary;
    return model;
}
@end
