//
//  ETViewController.m
//  winelist
//
//  Created by Erlend Thune on 26.04.14.
//  Copyright (c) 2014 Erlend Thune. All rights reserved.
//
// Icon source: http://www.freepik.com/free-vector/bottles-collection---set-of-different-drinks-and-bottles_682651.htm
//http://www.freepik.com/free-icon/man-saving-money-in-a-piggy-moneybox_704686.htm
// "Icon made by Freepik from Flaticon.com"
// http://makeappicon.com/
//http://svg-edit.googlecode.com/svn/branches/stable/editor/svg-editor.html

#import "ETViewController.h"
#import "ETAlertView.h"
#import "ETInternetconnection.h"
#import "ETStockViewController.h"


@interface ETViewController ()

@end

@implementation ETViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.buttonTintColor = self.filterButton.tintColor;
    self.orderByName = true;
    self.orderAscending = true;
    self.filter = 1;
    self.bytesReceived = 0;
    self.activeSegment = 0;
    self.dateRequestSource = 0;
    self.nagscreenOnDisplay = false;
    self.downloadState = 0;
    self.usageCounter = 0;
    self.queue = [FMDatabaseQueue databaseQueueWithPath:[Utility getDatabasePath]];
    self.fullWineList = [[NSMutableArray alloc] init];
    [self CreateBusyIndicator];
    [self ChangeSearchButton];
    [self GetDatabaseDate];
    self.dateRequestSource = 1;
    self.dbDateButton.tintColor = [UIColor blueColor];
    [self.dbDateButton setTarget:nil];
    [self.dbDateButton setAction:nil];
#ifdef GRATIS
    [self UpdateTimesUsedAndDisplayNagScreen];
    //Subscribe to events that application receives. This causes the nag screen to be activated when app is activated.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateTimesUsedAndDisplayNagScreen) name:UIApplicationWillEnterForegroundNotification object:nil];
#else
    [self performSelectorOnMainThread:@selector(ShowStartupDialog) withObject:nil waitUntilDone:NO];
#endif
    [self getWines];
}

//From http://stackoverflow.com/questions/2705865/change-uisearchbar-keyboard-search-button-title
-(void) ChangeSearchButton
{
    for(UIView *subView in [self.searchBar subviews]) {
        if([subView conformsToProtocol:@protocol(UITextInputTraits)]) {
            UITextField* tf = (UITextField *)subView;
            [tf setReturnKeyType: UIReturnKeyDone];
            tf.enablesReturnKeyAutomatically = NO;
        } else {
            for(UIView *subSubView in [subView subviews]) {
                if([subSubView conformsToProtocol:@protocol(UITextInputTraits)]) {
                    UITextField* tf = (UITextField *)subSubView;
                    [tf setReturnKeyType: UIReturnKeyDone];
                    tf.enablesReturnKeyAutomatically = NO;
                }
            }
        }
    }
}



/////////////////////////////
//Should be defined out in pay version BEGIN
/////////////////////////////

#ifdef GRATIS
-(void)UpdateTimesUsedAndDisplayNagScreen
{
    if(self.nagscreenOnDisplay)
    {
        return;
    }
    NSString *queryString= [NSString stringWithFormat:@"SELECT * FROM usage"];
    
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *results = [db executeQuery:queryString];
        
        if([results next])
        {
            self.usageCounter = [results intForColumn:@"noOfTimesUsed"] + 1;
            
            if(self.usageCounter > 10)
            {
                dispatch_async(dispatch_get_main_queue(),^ {
                    [self DisplayAlertView:self.usageCounter];
                } );
            }
            else
            {
                [self performSelectorOnMainThread:@selector(ShowStartupDialog) withObject:nil waitUntilDone:NO];
            }
            
            NSString *updateQueryString = [NSString stringWithFormat:@"UPDATE usage set noOfTimesUsed=%d", self.usageCounter];
            if(![db executeUpdate:updateQueryString])
            {
                NSLog(@"Failed to update usage");
            }
         }
        else
        {
            NSLog(@"Failed to get usage");
        }
        [results close];
    }];
}

- (void) DisplayAlertView:(int)noOfTimesUsed
{
    // Create the view
    
    int maxWidth = [[UIScreen mainScreen ]applicationFrame].size.width;
    int maxHeight = [[UIScreen mainScreen ]applicationFrame].size.height;
    int imgWidth = maxWidth-20;
    int imgHeight = maxHeight/3;
    
    self.alertView = [[ETAlertView alloc] init:imgWidth imgHeight:imgHeight noOfTimesUsed:noOfTimesUsed mvc:self];
    
    CGRect f = self.alertView.frame;
    f.origin.x = 10;
    f.origin.y = imgHeight;
    self.alertView.frame = f;
    
//    self.view.userInteractionEnabled=NO;
    [self.view addSubview:self.alertView];
}
/////////////////////////////
//Should be defined out in pay version END
/////////////////////////////

#endif

-(NSString*)CreatePrice:(NSString*)s
{
    NSLog(@"Price:%@", s);
    unsigned long dpos = [s length]-2;
    return [NSString stringWithFormat:@"%@,%@", [s substringToIndex:dpos], [s substringFromIndex:dpos]];
}

- (NSString*)GetWineTypeAsString:(int)type
{
    /*
     vintyper = {
     "0" => "rødvin",
     "1" => "hvitvin",
     "2" => "rosevin",
     "3" => "sterkvin",
     "4" => "musserendevin",
     "5" => "fruktvin",
     "6" => "brennevin",
     "7" => "øl",
     "8" => "perlendevin",
     "9" => "aromatisertvin",
     "10" => "sider",
     "11" => "alkoholfritt",
}
     */
    
    NSMutableString* sVinType;
    switch (type) {
        case 0:
            sVinType = [NSMutableString stringWithString:@"Rødvin"];
            break;
        case 1:
            sVinType = [NSMutableString stringWithString:@"Hvitvin"];
            break;
        case 2:
            sVinType = [NSMutableString stringWithString:@"Rosévin"];
            break;
        case 3:
            sVinType = [NSMutableString stringWithString:@"Sterkvin"];
            break;
        case 4:
            sVinType = [NSMutableString stringWithString:@"Musserende vin"];
            break;
        case 5:
            sVinType = [NSMutableString stringWithString:@"Fruktvin"];
            break;
        case 6:
            sVinType = [NSMutableString stringWithString:@"Brennevin"];
            break;
        case 7:
            sVinType = [NSMutableString stringWithString:@"Øl"];
            break;
        case 8:
            sVinType = [NSMutableString stringWithString:@"Perlende vin"];
            break;
        case 9:
            sVinType = [NSMutableString stringWithString:@"Aromatisert vin"];
            break;
        case 10:
            sVinType = [NSMutableString stringWithString:@"Sider"];
            break;
        case 11:
            sVinType = [NSMutableString stringWithString:@"Alkoholfritt"];
            break;
        default:
            sVinType = [NSMutableString stringWithString:@""];
            break;
    }
    return sVinType;
}

/*
 vintyper = {
 "0" => "rødvin",
 "1" => "hvitvin",
 "2" => "rosevin",
 "3" => "sterkvin",
 "4" => "musserendevin",
 "5" => "fruktvin",
 "6" => "brennevin",
 "7" => "øl",
 "8" => "perlendevin",
 "9" => "aromatisertvin",
 "10" => "sider",
 "11" => "alkoholfritt",
 }
 */

-(void)ShowStartupDialog
{
    if(self.filterMenuHasBeenDisplayed)
    {
        return;
    }
    self.filterMenuHasBeenDisplayed = true;
    [self ShowFilterDialogEx];
}

-(void)ShowFilterDialogEx
{
    NSMutableString *Alle = [NSMutableString stringWithString:@"Alle varer"];
    NSMutableString *Red = [NSMutableString stringWithString:@"Rødvin"];
    NSMutableString *White = [NSMutableString stringWithString:@"Hvitvin"];
    NSMutableString *Rose = [NSMutableString stringWithString:@"Rosévin"];
    NSMutableString *Muss = [NSMutableString stringWithString:@"Musserende vin"];
    NSMutableString *Sterk = [NSMutableString stringWithString:@"Sterkvin"];
    NSMutableString *Brenn = [NSMutableString stringWithString:@"Brennevin"];
    NSMutableString *Frukt = [NSMutableString stringWithString:@"Fruktvin"];
    NSMutableString *Beer = [NSMutableString stringWithString:@"Øl"];
    NSMutableString *Perlendevin = [NSMutableString stringWithString:@"Perlende vin"];
    NSMutableString *Aromatisertvin = [NSMutableString stringWithString:@"Aromatisert vin"];
    NSMutableString *Sider = [NSMutableString stringWithString:@"Sider"];
    NSMutableString *Alkoholfritt = [NSMutableString stringWithString:@"Alkoholfritt"];
    
    NSArray *filterArray = [NSArray arrayWithObjects:Alle,Red,White,Rose,Sterk,Muss,Frukt,Brenn,Beer,Perlendevin,Aromatisertvin,Sider,Alkoholfritt,nil];
    
    for (int i = 0; i < [filterArray count]; i++)
    {
        id object = [filterArray objectAtIndex:i];
        if(i == self.filter)
        {
            [object insertString:@"✔ " atIndex:0];
        }
        else
        {
            [object insertString:@"  " atIndex:0];
        }
    }
    
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:@"Vis" delegate:self cancelButtonTitle:@"Ok" destructiveButtonTitle:nil otherButtonTitles:
                            Alle,
                            Red,
                            White,
                            Rose,
                            Sterk,
                            Muss,
                            Frukt,
                            Brenn,
                            Beer,
                            Perlendevin,
                            Aromatisertvin,
                            Sider,
                            Alkoholfritt,
                            nil];
    
//    [popup showInView:[UIApplication sharedApplication].keyWindow];
    [popup showInView:self.view];
}

- (IBAction)ShowFilterDialog:(id)sender {
    [self ShowFilterDialogEx];
}


- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
    {
        [self.filterButton setTintColor:self.buttonTintColor];
    }
    else
    {
        [self.filterButton setTintColor:[UIColor redColor]];
    }

    if((self.filter == buttonIndex) || (buttonIndex > 12)) // The user pressed cancel or did not change the selection.
    {
        return;
    }
    self.filter = (int)buttonIndex;
    [self getWines];
}

-(void)CreateBusyIndicator
{
    int maxWidth = [[UIScreen mainScreen ]applicationFrame].size.width;
    int maxHeight = [[UIScreen mainScreen ]applicationFrame].size.height;
    CGRect frame = CGRectMake(0,0,maxWidth,maxHeight);
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.activityIndicator setColor:[UIColor redColor]];
    self.activityIndicator.frame = frame;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];
}

- (IBAction)segmentChanged:(id)sender {
    long newSegment = self.wineSegment.selectedSegmentIndex;
    if(newSegment == self.activeSegment)
    {
        self.orderAscending = !self.orderAscending;
    }
    
    if(newSegment == 0)
    {
        self.orderByName = true;
    }
    else
    {
        self.orderByName = false;
    }
    self.activeSegment = newSegment;
    [self getWines];
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.fullWineList count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"winecell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    long i = [indexPath row];
    
    Wine *wine;


    wine = [self.fullWineList objectAtIndex:i];
    cell.textLabel.text = wine.name;
    
    NSString *sVinType = [self GetWineTypeAsString:wine.type];

    NSString *s = [NSString stringWithFormat:@"%@ kr.%@ %@", sVinType, wine.price, wine.volume];
    cell.detailTextLabel.text = s;
    return cell;
}

- (NSMutableString*) GetSearchString
{
    NSMutableString *searchString;
    searchString = [NSMutableString stringWithFormat:@"SELECT * FROM vino"];

    NSString* ss = [[self searchBar] text];
    bool bFirst = true;
    if ([ss length] != 0)
    {
        NSString* trimmedString = [ss stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *listItems = [trimmedString componentsSeparatedByString:@" "];
        
        for (id s in listItems) {
            if(bFirst)
            {
                [searchString appendString:@" WHERE name LIKE "];
                bFirst = false;
            }
            else
            {
                [searchString appendString: @" AND name like "];
                
            }
            [searchString appendFormat: @"\"%%%@%%\"", s];
        }
    }
    
    if(self.filter)
    {
        if(bFirst)
        {
            [searchString appendString:@" WHERE "];
        }
        else
        {
            [searchString appendString:@" AND "];
        }
        [searchString appendFormat: @" type=%d", self.filter-1]; //-1 because 0 means all types in UI.
    }
    
    if(self.orderByName)
    {
        [searchString appendString: @" ORDER BY name"];
    }
    else
    {
        [searchString appendString: @" ORDER BY price"];
    }
    if(self.orderAscending)
    {
        [searchString appendString: @" ASC"];
    }
    else
    {
        [searchString appendString: @" DESC"];
    }
    return searchString;
}

-(void)UpdateWineList:(NSMutableArray*)arr
{
    self.fullWineList = arr;
    [self.wineTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    [self.wineTableView reloadData];
}


- (void)getWines
{
    [self.view bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startAnimating];

    NSMutableString *searchString = [self GetSearchString];
    [self setCurrentSearchString:searchString];

    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.erlendthune.ios.fts.search", NULL);
    dispatch_async(backgroundQueue, ^(void){
        [self.queue inDatabase:^(FMDatabase *db) {
            NSMutableArray *arr = [[NSMutableArray alloc] init];
            FMResultSet *results = [db executeQuery:searchString];
            while ([results next]) {
                //If search string has changed, we abort this search.
                if (![[self currentSearchString] isEqualToString:searchString]) {
                    [results close];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.activityIndicator stopAnimating];
                    });
                    return;
                }
                Wine *wine = [[Wine alloc] init];
                
                wine.id = [results intForColumn:@"id"];
                wine.type = [results intForColumn:@"type"];
                wine.name = [results stringForColumn:@"name"];
                wine.volume = [results stringForColumn:@"volume"];
                wine.price = [self CreatePrice:[results stringForColumn:@"price"]];
                
                [arr addObject:wine];
            }
            [results close];
            
            //No point in calling reload if another search is going on.
            if (![[self currentSearchString] isEqualToString:searchString])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.activityIndicator stopAnimating];
                });
                return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog( @"thread: calling reload" );
                [self UpdateWineList:arr];
                [self.activityIndicator stopAnimating];
            });
        }];
    });
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	[self getWines];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
//	[self getWines];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)Get:(NSString*)address
{
    // Create the request.
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:address]];
    
    // Create url connection and fire request
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(!conn)
    {
        [self alertMessage:@"Feil" s:@"Klarte ikke opprette forbindelse til serveren."];
    }
}

#pragma mark NSURLConnection Delegate Methods
- (void) DisplayInternetView
{
    self.bytesReceived = 0;
    // Create the view
    
    int maxWidth = [[UIScreen mainScreen ]applicationFrame].size.width;
    int maxHeight = [[UIScreen mainScreen ]applicationFrame].size.height;
    int imgWidth = maxWidth*6/8;
    int imgHeight = maxHeight/2;
    
    self.internetView = [[ETInternetconnection alloc] init:imgWidth imgHeight:imgHeight];
    
    CGRect f = self.internetView.frame;
    f.origin.x = maxWidth/10;
    f.origin.y = imgHeight/2;
    self.internetView.frame = f;
    
    [self.view addSubview:self.internetView];
    NSString *address = @"https://www-erlendthune-com.secure.domeneshop.no/vin/vino.txt";
    [self.internetView UpdateLabelText:@"Sjekker..."];
    
    [self Get:address];
}
- (IBAction)checkForDatabaseUpdates:(id)sender {
    //This method will call GetDatabaseResult
    [self GetDatabaseDate];
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // the user clicked OK
    switch (alertView.tag) {
        case 1:
            if (buttonIndex == 1) {
                [self DisplayInternetView];
            }
            break;
        case 2:
        {
            if (buttonIndex == 1) {
                self.downloadState = 1;
                NSString* address = @"https://www-erlendthune-com.secure.domeneshop.no/vin/vino.db";
                [self.internetView UpdateLabelText:@"Laster ned..."];
                [self Get:address];
            }
            else
            {
                [self.internetView removeFromSuperview];
            }
        }
            
        default:
            break;
    }
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    [self.internetView UpdateLabelText:@"Mottar data..."];
    self.responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    self.bytesReceived++;
    NSString *s =[[NSString alloc] initWithFormat:@"Mottar data: %ld", self.bytesReceived];
    [self.internetView UpdateLabelText:s];
    [self.responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    NSLog(@"Internetconnection finish.");
    if(self.downloadState == 0)
    {
        [self.internetView UpdateLabelText:@""];
        
        NSString * s = [[NSString alloc] initWithBytes:self.responseData.bytes length:self.responseData.length encoding:NSASCIIStringEncoding];
        int newdatabasedate = [s intValue];
        if(newdatabasedate == self.databasedate)
        {
            [self.internetView removeFromSuperview];
            [self alertMessage:@"Database" s:@"Du har den nyeste databasen."];
        }
        else
        {
            NSDate *newdbdate = [[NSDate alloc] initWithTimeIntervalSince1970:newdatabasedate];
            NSDate *currentdbdate = [[NSDate alloc] initWithTimeIntervalSince1970:self.databasedate];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//            [dateFormat setDateFormat:@"dd. MMM yyyy"];
            [dateFormat setDateStyle:NSDateFormatterMediumStyle];
            NSString *newDate = [dateFormat stringFromDate:newdbdate];
            NSString *currentDate = [dateFormat stringFromDate:currentdbdate];

            NSString *msg = [NSString stringWithFormat:@"Din database er fra %@. En database fra %@ er tilgjengelig. Vil du laste den ned?", currentDate, newDate];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Database"
                                                            message:msg
                                                           delegate:self
                                                  cancelButtonTitle:@"Avbryt"
                                                  otherButtonTitles:@"Ja", nil];
            alert.tag = 2;
            [alert show];
        }
    }
    else
    {
        self.downloadState = 0;
        [self.internetView UpdateLabelText:@"Lagrer database"];
        NSString* databasePath = [Utility getDatabasePath];
        [self.internetView removeFromSuperview];
        if([self.responseData writeToFile:databasePath atomically:YES])
        {
            [self.queue close];
            self.queue = [FMDatabaseQueue databaseQueueWithPath:databasePath];
            [self getWines];
            self.dateRequestSource = 0;
            [self GetDatabaseDate];
            self.dateRequestSource = 1;
            
            [self UpdateUsageCounterInDatabase];

            [self alertMessage:@"Database" s:@"Du har nå den nyeste utgaven av databasen."];
        }
        else
        {
            [self alertMessage:@"Database" s:@"Klarte ikke å lagre den nye databasen."];
        }
    }
}

-(void)UpdateUsageCounterInDatabase
{
    [self.queue inDatabase:^(FMDatabase *db) {
        NSString *updateQueryString = [NSString stringWithFormat:@"UPDATE usage set noOfTimesUsed=%d", self.usageCounter];
        if(![db executeUpdate:updateQueryString])
        {
            NSLog(@"Failed to update usage");
        }
    }];
}

-(void)GetDatabasedateResult
{
    NSDate *dbdate = [[NSDate alloc] initWithTimeIntervalSince1970:self.databasedate];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//    [dateFormat setDateFormat:@"dd. MMM yyyy"];
    [dateFormat setDateStyle:NSDateFormatterMediumStyle];
    NSString *theDate = [dateFormat stringFromDate:dbdate];
    if(self.dateRequestSource == 0)
    {
        NSString* buttonTitle = [NSString stringWithFormat:@"Priser fra %@", theDate];
        self.dbDateButton.title = buttonTitle;
    }
    else
    {
        NSString *msg = [NSString stringWithFormat:@"Din database er fra %@. Vil du undersøke om en nyere er tilgjengelig?", theDate];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Database"
                                                        message:msg
                                                       delegate:self
                                              cancelButtonTitle:@"Avbryt"
                                              otherButtonTitles:@"Ja", nil];
        alert.tag = 1;
        [alert show];
    }
}

-(void) GetDatabaseDate
{
    NSString *queryString= [NSString stringWithFormat:@"SELECT * FROM vinodate"];
    [self.queue inDatabase:^(FMDatabase *db) {
        int datecreated = 0;
        FMResultSet *results = [db executeQuery:queryString];
        
        if([results next])
        {
            datecreated = [results intForColumn:@"datecreated"];
        }
        else
        {
            NSLog(@"Failed to get datecreated");
        }
        [results close];
        self.databasedate = datecreated;
        [self GetDatabasedateResult];
    }];
}

-(void)alertMessage:(NSString*)t s:(NSString*)s
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:t
                                                    message:s
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    alert.tag = 1;
    [alert show];
}



- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    [self.internetView removeFromSuperview];
    NSLog(@"Internetconnection error:%@", error.description);
    [self alertMessage:@"Feil" s:error.localizedDescription];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showRecipeDetail"]) {
        NSIndexPath *indexPath = [self.wineTableView indexPathForSelectedRow];
        ETStockViewController *destViewController = segue.destinationViewController;
        Wine *wine;
        wine = [self.fullWineList objectAtIndex:indexPath.row];
        destViewController.sku = wine.id;
    }
}


@end
