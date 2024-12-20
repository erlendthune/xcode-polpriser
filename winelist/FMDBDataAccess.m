//
//  FMDBDataAccess.m
//  Chanda
//
//  Created by Mohammad Azam on 10/25/11.
//  Copyright (c) 2011 HighOnCoding. All rights reserved.
//

#import "FMDBDataAccess.h"

@implementation FMDBDataAccess
FMDatabaseQueue *queue;

- (id) init
{
    if (self = [super init])
    {
        queue = [FMDatabaseQueue databaseQueueWithPath:[Utility getDatabasePath]];
    }
    return self;
}

@end
