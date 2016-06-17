//
//  SimpleRow.h
//  ExampleApp
//
//  Created by wang dong on 4/13/14.
//  Copyright (c) 2014 Thong Nguyen. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "BaseModel.h"


@interface SimpleRow : BaseModel
@property (weak)NSNumber* date;
@property (weak)NSNumber* commitedDate;
@property (weak)NSString* name;
@property (weak)NSString* label;
@property (weak)NSString* memo;
@property (assign)BOOL hidden;
@property (weak)NSNumber* flag;
@property (weak)NSMutableArray* files;
@property (assign) int downloadCount;
@end

@interface SimpleAllCom : BaseModel
@property (weak)NSMutableArray* rows;
@end
