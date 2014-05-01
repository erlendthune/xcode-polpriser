//
//  FMDBDataAccess.h
//  Chanda
//
//  Created by Mohammad Azam on 10/25/11.
//  Copyright (c) 2011 HighOnCoding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h" 
#import "FMResultSet.h" 
#import "FMDatabaseQueue.h"
#import "Utility.h"
#import "Wine.h"

@interface FMDBDataAccess : NSObject
{
    
}

-(NSMutableArray *) getWines;

@end
