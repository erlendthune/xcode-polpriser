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

-(NSMutableArray *) getWines
{
    NSMutableArray *wines = [[NSMutableArray alloc] init];
    
//    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    
//    [db open];
    
//    FMResultSet *results = [db executeQuery:@"SELECT * FROM vino"];
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:@"SELECT * FROM vino"];

        while([results next])
        {
            Wine *wine = [[Wine alloc] init];
            
            wine.id = [results intForColumn:@"id"];
            wine.name = [results stringForColumn:@"name"];
            wine.volume = [results stringForColumn:@"volume"];
            wine.price = [results stringForColumn:@"price"];
            
            [wines addObject:wine];
            
        }
    }];
    
//    [db close];
  
    return wines;

}

@end
