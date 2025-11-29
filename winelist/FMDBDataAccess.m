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
