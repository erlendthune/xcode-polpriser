//
//  ETViewController.m
//  winelist
//
//  Created by Erlend Thune on 26.04.14.
//  Copyright (c) 2014 Erlend Thune. All rights reserved.
//

#import "ETViewController.h"
#import "ETAlertView.h"

@interface ETViewController ()

@end

@implementation ETViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.orderByName = true;
    self.activeSegment = 0;
    self.queue = [FMDatabaseQueue databaseQueueWithPath:[Utility getDatabasePath]];
    self.fullWineList = [[NSMutableArray alloc] init];
    [self getWines:0]; //Loads redwine
    self.filteredWineList = [[NSMutableArray alloc] init];
    // Do any additional setup after loading the view.
    [self UpdateTimesUsedAndDisplayNagScreen];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateTimesUsedAndDisplayNagScreen) name:UIApplicationWillEnterForegroundNotification object:nil];
}


-(void)UpdateTimesUsedAndDisplayNagScreen
{

    NSString *queryString= [NSString stringWithFormat:@"SELECT * FROM usage"];
    
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:queryString];
        
        if([results next])
        {
            int noOfTimesUsed = [results intForColumn:@"noOfTimesUsed"] + 1;
            
            if(noOfTimesUsed > 3)
            {
                dispatch_async(dispatch_get_main_queue(),^ {
                    [self DisplayAlertView:noOfTimesUsed];
                } );
            }
            NSString *updateQueryString = [NSString stringWithFormat:@"UPDATE usage set noOfTimesUsed=%d", noOfTimesUsed];
            if(![db executeUpdate:updateQueryString])
            {
                NSLog(@"Failed to update usage");
            }
 
/*
            dispatch_async(dispatch_get_main_queue(),^ {
                [self UpdateTimesUsed:noOfTimesUsed];
            } );
*/
        }
        else
        {
            NSLog(@"Failed to get usage");
        }
        [results close];
    }];
}

-(NSString*)CreatePrice:(NSString*)s
{
    unsigned long dpos = [s length]-2;
    return [NSString stringWithFormat:@"%@,%@", [s substringToIndex:dpos], [s substringFromIndex:dpos]];
}

/////////////////////////////
//Should be defined out in pay version BEGIN
/////////////////////////////
- (void) DisplayAlertView:(int)noOfTimesUsed
{
    // Create the view
    
    int maxWidth = [[UIScreen mainScreen ]applicationFrame].size.width;
    int maxHeight = [[UIScreen mainScreen ]applicationFrame].size.height;
    int imgWidth = maxWidth-20;
    int imgHeight = maxHeight/2;
    
    self.alertView = [[ETAlertView alloc] init:imgWidth imgHeight:imgHeight noOfTimesUsed:noOfTimesUsed];
    
    CGRect f = self.alertView.frame;
    f.origin.x = 10;
    f.origin.y = imgHeight/2;
    self.alertView.frame = f;
    
    // Add card to view
    [self.view addSubview:self.alertView];
}
/////////////////////////////
//Should be defined out in pay version END
/////////////////////////////

-(void) getWines:(long) wineType
{
    //    FMDatabase *db = [FMDatabase databaseWithPath:[Utility getDatabasePath]];
    
    //    [db open];
    
    //    FMResultSet *results = [db executeQuery:@"SELECT * FROM vino"];
    NSMutableString *loadString;
    if(wineType > 1)
    {
        loadString= [NSMutableString stringWithFormat:@"SELECT * FROM vino"];
    }
    else
    {
        loadString= [NSMutableString stringWithFormat:@"SELECT * FROM vino WHERE type=%ld", wineType];
    }

    if(self.orderByName)
    {
        [loadString appendString: @" ORDER BY name"];
    }
    else
    {
        [loadString appendString: @" ORDER BY price"];
    }
    
    [self.fullWineList removeAllObjects];
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:loadString];
        
        while([results next])
        {
            Wine *wine = [[Wine alloc] init];
            
            wine.id = [results intForColumn:@"id"];
            wine.name = [results stringForColumn:@"name"];
            wine.volume = [results stringForColumn:@"volume"];
            wine.price = [self CreatePrice:[results stringForColumn:@"price"]];
            
            [self.fullWineList addObject:wine];
            
        }
    }];
    //    [db close];
}
- (IBAction)segmentChanged:(id)sender {
    long newSegment = self.wineSegment.selectedSegmentIndex;
    if(newSegment == self.activeSegment)
    {
        self.orderByName = !self.orderByName; //Toggle ordering
    }
    self.activeSegment = newSegment;
    [self getWines:self.activeSegment];
    [self setCurrentSearchString:nil];
    [self performSearch];
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ([[[self searchBar] text] length] > 0) {
        return [self.filteredWineList count];
	} else {
        return [self.fullWineList count];
	}
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"winecell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    long i = [indexPath row];
    
    Wine *wine;
    
	if ([[[self searchBar] text] length] > 0) {
        wine = [self.filteredWineList objectAtIndex:i];
	} else {
        wine = [self.fullWineList objectAtIndex:i];
	}
    
    cell.textLabel.text = wine.name;

    NSString *s = [NSString stringWithFormat:@"kr.%@ %@", wine.price, wine.volume];
    cell.detailTextLabel.text = s;
    return cell;
}

- (void)performSearch
{
    if ([[[self searchBar] text] length] == 0) {
        [self setCurrentSearchString:nil];
        [self.wineTableView reloadData];
//        [self.activityIndicator stopAnimating];
        return;
    }
    
//    [[self activityIndicator] startAnimating];
    
//    NSString *searchString = [NSString stringWithFormat:@"%@*", [[self searchBar] text]];
    NSString* ss = [[self searchBar] text];
    NSString* trimmedString = [ss stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray *listItems = [trimmedString componentsSeparatedByString:@" "];
    
    NSMutableString *searchString;
    if(self.activeSegment > 1)
    {
        searchString = [NSMutableString stringWithFormat:@"SELECT * FROM vino WHERE name LIKE "];
    }
    else
    {
        searchString = [NSMutableString stringWithFormat:@"SELECT * FROM vino WHERE type=%ld AND name LIKE ", self.activeSegment];
    }
    
    bool bFirst = true;
    for (id s in listItems) {
        if(bFirst)
        {
            bFirst = false;
        }
        else
        {
            [searchString appendString: @" AND name like "];
            
        }
        [searchString appendFormat: @"\"%%%@%%\"", s];
    }
    
    if(self.orderByName)
    {
        [searchString appendString: @" ORDER BY name"];
    }
    else
    {
        [searchString appendString: @" ORDER BY price"];
    }
    
    [self setCurrentSearchString:searchString];
    
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.erlendthune.ios.fts.search", NULL);
    int64_t delay = 0.5;
    if ([[[self searchBar] text] length] > 3) {
        delay = 0.0;
    }
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(time, backgroundQueue, ^(void){
        if (![[self currentSearchString] isEqualToString:searchString]) {
            return;
        }
        
        [self.queue inDatabase:^(FMDatabase *db) {
            //NSMutableArray *arr = [[NSMutableArray alloc] init];
            [self.filteredWineList removeAllObjects];
            FMResultSet *results = [db executeQuery:searchString];
            while ([results next]) {
                if (![[self currentSearchString] isEqualToString:searchString]) {
                    [results close];
                    return;
                }
                Wine *wine = [[Wine alloc] init];
                
                wine.id = [results intForColumn:@"id"];
                wine.name = [results stringForColumn:@"name"];
                wine.volume = [results stringForColumn:@"volume"];
                wine.price = [self CreatePrice:[results stringForColumn:@"price"]];
                
                [self.filteredWineList addObject:wine];
            }
            [results close];
            
            if (![[self currentSearchString] isEqualToString:searchString]) {
                return;
            }
            
            if (![[self currentSearchString] isEqualToString:searchString])
            {
                return;
            }
            //self.filteredWineList = arr;
            NSLog( @"thread: calling reload" );
            [self.wineTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
		}];
	});
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	[self performSearch];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
	[self performSearch];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
