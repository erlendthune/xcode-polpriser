#import "Utility.h"

@implementation Utility

+(NSString *) getDatabasePath
{
     NSString *databasePath = [(ETAppDelegate *)[[UIApplication sharedApplication] delegate] databasePath];
    
    return databasePath; 
}

@end
