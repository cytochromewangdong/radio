//
//  SimpleRow.m
//  ExampleApp
//
//  Created by wang dong on 4/13/14.
//  Copyright (c) 2014 Thong Nguyen. All rights reserved.
//

#import "SimpleRow.h"

@implementation SimpleRow

-(BOOL) isEqual:(id)other
{
    if(self==other)
    {
        return YES;
    }
    if([other isKindOfClass:[SimpleRow class]])
    {
        return [self.name isEqualToString:((SimpleRow*)other).name];
    } else {
        return NO;
    }
}
- (NSUInteger)hash
{
    return [self.name hash];
}
@dynamic name;

-(NSString*) name
{
    return [self.dataDict valueForKey:@"name"];
}
-(void) setName:(NSString *)name
{
    [self.dataDict setValue:name forKey:@"name"];
    self.label =  [[name lastPathComponent] stringByDeletingPathExtension];
}
@dynamic hidden;
-(BOOL) hidden
{
    return [[self.dataDict valueForKey:@"hidden"]boolValue];
}
-(void) setHidden:(BOOL)hidden
{
    [self.dataDict setValue:hidden?@"true":@"false" forKey:@"hidden"];
}

@dynamic label;

-(NSString*) label
{
    return [self.dataDict valueForKey:@"label"];
}
-(void) setLabel:(NSString *)label
{
    [self.dataDict setValue:label forKey:@"label"];
}
@dynamic memo;

-(NSString*) memo
{
    return [self.dataDict valueForKey:@"memo"];
}
-(void) setMemo:(NSString *)memo
{
    [self.dataDict setValue:memo forKey:@"memo"];
}

@dynamic date;

-(NSNumber*) date
{
    return [self.dataDict valueForKey:@"date"];
}
-(void) setDate:(NSNumber *)date
{
    [self.dataDict setValue:date forKey:@"date"];
}
@dynamic flag;

-(NSNumber*) flag
{
    return [self.dataDict valueForKey:@"flag"];
}
-(void) setFlag:(NSNumber *)flag
{
    [self.dataDict setValue:flag forKey:@"flag"];
}
@dynamic commitedDate;
-(NSNumber*) commitedDate
{
    return [self.dataDict valueForKey:@"commitedDate"];
}
-(void) setCommitedDate:(NSNumber *)commitedDate
{
    [self.dataDict setValue:commitedDate forKey:@"commitedDate"];
}
@dynamic files;
-(NSMutableArray*) files
{
    NSMutableArray* ret=[[NSMutableArray alloc]init];
    NSMutableArray* rawData = [self.dataDict valueForKey:@"files"];
    if(rawData && [rawData isKindOfClass:[NSArray class]]) {
        for(NSMutableDictionary *row in rawData) {
            SimpleRow* objMyAccount=[[SimpleRow alloc]init];
            objMyAccount.dataDict=row;
            [ret addObject:objMyAccount];
        }
    }
    return ret;
}
-(void) setRows:(NSMutableArray*) files
{
    if(files){
        NSMutableArray* rawDataRows=[[NSMutableArray alloc]init];
        for(SimpleRow *row in files) {
            [rawDataRows addObject:row.dataDict];
        }
        [self.dataDict setValue: rawDataRows forKey:@"files"];
    } else
        [self.dataDict setValue: nil forKey:@"files"];
}
@end


@implementation SimpleAllCom

@dynamic rows;
-(NSMutableArray*) rows
{
    NSMutableArray* ret=[[NSMutableArray alloc]init];
    NSMutableArray* rawData = [self.dataDict valueForKey:@"rows"];
    if(rawData) {
        for(NSMutableDictionary *row in rawData) {
            SimpleRow* objMyAccount=[[SimpleRow alloc]init];
            objMyAccount.dataDict=row;
            [ret addObject:objMyAccount];
        }
    }
    return ret;
}
-(void) setRows:(NSMutableArray*) rows
{
    if(rows){
        NSMutableArray* rawDataRows=[[NSMutableArray alloc]init];
        for(SimpleRow *row in rows) {
            [rawDataRows addObject:row.dataDict];
        }
        [self.dataDict setValue: rawDataRows forKey:@"rows"];
    } else
        [self.dataDict setValue: nil forKey:@"rows"];
}

@end
