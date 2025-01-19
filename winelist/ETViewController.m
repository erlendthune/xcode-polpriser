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

#define ORDER_BY_NAME 0
#define ORDER_BY_PRICE 1
#define ORDER_BY_VOLUME 2
#define ORDER_BY_ALCOHOL_CONTENT 3
#define ORDER_BY_PRICE_PER_VOLUME_UNIT 4
#define ORDER_BY_PRICE_PER_ALCOHOL_UNIT 5

#import "ETViewController.h"
#import "HRMAPHelper.h"

#import "ETAlertView.h"
#import "ETInternetconnection.h"
#import "ETStockViewController.h"
#import "ETHelpViewController.h"

@interface ETViewController ()

@end

@implementation ETViewController

-(void)requestDidFinish:(SKRequest*)request{
    if([request isKindOfClass:[SKReceiptRefreshRequest class]]){
        NSLog(@"Found receipt.");
        [[HRMAPHelper sharedInstance] validateReceipt:self];
    }
}

- (void)request:(SKRequest*)request didFailWithError:(NSError *)error{
    NSLog(@"Could not find receipt. Try to restore purchase.");
    [[HRMAPHelper sharedInstance] restoreCompletedTransactions];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.wineSegment.apportionsSegmentWidthsByContent = YES;
    self.buttonTintColor = self.filterButton.tintColor;
    self.orderBy = ORDER_BY_NAME;
    self.orderAscending = true;
    self.primaryOrderAscending = true;
    self.primaryOrderKeyActive = false;
    self.filter = 0;
    self.menuButton.title = @"\u2630";
    self.restorePurchaseStarted = false;
    self.bytesReceived = 0;
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
//    [self.dbDateButton setTarget:nil];
//    [self.dbDateButton setAction:nil];

    _purchased = [[HRMAPHelper sharedInstance] productPurchased:@"com.erlendthune.polpriser"];
    
    if(!_purchased)
    {
        [[HRMAPHelper sharedInstance] validateReceipt:self];
    }
    //Subscribe to events that application receives. This causes the nag screen to be activated when app is activated.
    [self getWines];
    [self updateSortArrows];

    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:12]};
    [self.wineSegment setTitleTextAttributes:attributes forState:UIControlStateNormal];

     UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
     [self.wineSegment addGestureRecognizer:longPress];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if(self.primaryOrderKeyActive)
        {
            self.primaryOrderKeyActive = false;
            [self removePrimaryKeySymbolFromSegment];
        }
        else
        {
            self.primaryOrderKeyActive = true;
            self.primaryOrderKey = self.orderBy;
            self.primaryOrderAscending = self.orderAscending;
            [self updatePrimaryKeySegment];
        }
        [self updateSortArrows];
        [self getWines];
    }
}

- (void) removePrimaryKeySymbolFromSegment
{
    NSString *originalTitle = [self.wineSegment titleForSegmentAtIndex:self.primaryOrderKey];
    
    NSString *newTitle = [originalTitle stringByReplacingOccurrencesOfString:@"🔑" withString:@""];
    
    [self.wineSegment setTitle:newTitle forSegmentAtIndex:self.primaryOrderKey];
}

- (void) updatePrimaryKeySegment {
    NSString *selectedTitle = [self.wineSegment titleForSegmentAtIndex:self.primaryOrderKey];
    NSString *updatedTitle = [NSString stringWithFormat:@"%@🔑", selectedTitle];
    [self.wineSegment setTitle:updatedTitle forSegmentAtIndex:self.primaryOrderKey];

    NSDictionary *boldAttributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:14]};
    [self.wineSegment setTitleTextAttributes:boldAttributes forState:UIControlStateNormal];
}

- (void)AppNotPurchased
{
    if(_restorePurchaseStarted)
    {
        [[HRMAPHelper sharedInstance] restoreCompletedTransactions];
        _restorePurchaseStarted = false;
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(),^ {
            [self getPrice];
        } );
    }
}


- (void)AppPurchased
{
    dispatch_async(dispatch_get_main_queue(),^ {
        [[HRMAPHelper sharedInstance] storePurchase:@"com.erlendthune.polpriser"];
    } );
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restorePurchaseFailed:) name:IAPHelperProductRestorePurchaseError object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseFailed:) name:IAPHelperProductPurchasedError object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchasedAlready:) name:IAPHelperProductAlreadyPurchased object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionFinished:) name:IAPHelperTransactionFinished object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)getPrice
{
    _price = nil;
    [[HRMAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success)
        {
            if([products count])
            {
                SKProduct* p = [products objectAtIndex:0]; //We only have one product.
                if(p)
                {
                    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                    [numberFormatter setLocale:p.priceLocale];
                    self->_price = [numberFormatter stringFromNumber:p.price];
                }
                else
                {
                    NSLog(@"getPrice no product at position 0.");
                }
            }
            else
            {
                NSLog(@"getPrice no products.");
            }
        }
        else
        {
            NSLog(@"getPrice failed to get products.");
        }
        dispatch_async(dispatch_get_main_queue(),^ {
            [self UpdateTimesUsedAndDisplayNagScreen];
        } );
        dispatch_async(dispatch_get_main_queue(),^ {
            [self GetNotifiedWhenAppEntersForeground];
        } );
    }];
}

- (void)purchase
{
    [_activityIndicator startAnimating];
    [[HRMAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success)
        {
            if([products count])
            {
                SKProduct* p = [products objectAtIndex:0]; //We only have one product.
                if(p)
                {
                    bool canMakePayments = [[HRMAPHelper sharedInstance] buyProduct:p];
                    if(!canMakePayments)
                    {
                        [self alertMessage:@"Kjøp" s:@"Du har ikke lov til å foreta kjøp."];
                    }
                }
                else
                {
                    [self alertMessage:@"Kjøp" s:@"Fant ingenting å kjøpe."];
                    [self->_activityIndicator stopAnimating];
                }
            }
            else
            {
                [self alertMessage:@"Kjøp" s:@"Fant ingenting å kjøpe."];
                [self->_activityIndicator stopAnimating];
            }
        }
        else
        {
            [self alertMessage:@"Kjøp" s:@"Kunne ikke koble til App store."];
            [self->_activityIndicator stopAnimating];
        }
    }];
}

- (void)restoreReceipt
{
    SKReceiptRefreshRequest* request = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];
    request.delegate = self;
    [request start];
    
}

- (void)restorePurchase
{
    [_activityIndicator startAnimating];
    
    _restorePurchaseStarted = true;
    
    //First try to restore the receipt. If it fails it will try to restore the purchase.
    [self restoreReceipt];
}

- (void)productPurchased:(NSNotification *)notification {
    NSLog(@"Product purchased. Remove buy buttons");
    _purchased = true;
    [_activityIndicator stopAnimating];
    [self alertMessage:@"Informasjon" s:@"Takk! App'en er nå låst opp."];
}

- (void)restorePurchaseFailed:(NSNotification *)notification
{
    [self alertMessage:@"Informasjon" s:@"Klarte ikke å koble til App store."];
    [_activityIndicator stopAnimating];
}

- (void)purchasedAlready:(NSNotification *)notification
{
    [self alertMessage:@"Informasjon" s:@"Du har allerede kjøpt app'en."];
}

- (void)purchaseFailed:(NSNotification *)notification
{
    [self alertMessage:@"Informasjon" s:@"Klarte ikke å koble til App store."];
    [_activityIndicator stopAnimating];
}
- (void)transactionFinished:(NSNotification *)notification
{
    if(!_purchased)
    {
        [self alertMessage:@"Informasjon" s:@"Du har ikke kjøpt app'en."];
    }
    [_activityIndicator stopAnimating];
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

-(void) GetNotifiedWhenAppEntersForeground
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(UpdateTimesUsedAndDisplayNagScreen) name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void)UpdateTimesUsedAndDisplayNagScreen
{
    if(_purchased)
    {
        return;
    }
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
            
            NSLog(@"Times used:%d", self.usageCounter);
            if(self.usageCounter > 10)
            {
                dispatch_async(dispatch_get_main_queue(),^ {
                    bool nag = true;
                    [self DisplayAlertView:self.usageCounter nag:nag];
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

- (void) DisplayAlertView:(int)noOfTimesUsed  nag:(bool)nag
{
    // Create the view
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat maxWidth = screenBounds.size.width;
    CGFloat maxHeight = screenBounds.size.height;
    int imgWidth = maxWidth-20;
    int imgHeight = maxHeight-maxHeight/6;
    
    self.alertView = [[ETAlertView alloc] init:imgWidth imgHeight:imgHeight noOfTimesUsed:noOfTimesUsed mvc:self nag:nag];
    
    CGRect f = self.alertView.frame;
    f.origin.x = 10;
    f.origin.y = maxHeight/8;
    self.alertView.frame = f;
    
//    self.view.userInteractionEnabled=NO;
    [self.view addSubview:self.alertView];
}


-(NSString*)CreatePrice:(NSString*)s
{
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
     "12" => "sake",
     "13" => "mjød"
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
        case 12:
            sVinType = [NSMutableString stringWithString:@"Sake"];
            break;
        case 13:
            sVinType = [NSMutableString stringWithString:@"Mjød"];
            break;
        default:
            sVinType = [NSMutableString stringWithString:@""];
            break;
    }
    return sVinType;
}

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
    NSMutableString *Sake = [NSMutableString stringWithString:@"Sake"];
    NSMutableString *Mjød = [NSMutableString stringWithString:@"Mjød"];

    NSArray *filterArray = [NSArray arrayWithObjects:
        Alle,
        Red,White,Rose,
        Sterk,Muss,Frukt,Brenn,
        Beer,Perlendevin,Aromatisertvin,
        Sider,Alkoholfritt,Sake,Mjød,nil];
    
    UIAlertController* alert = [
                                UIAlertController alertControllerWithTitle:nil
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];

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
        UIAlertAction* filterAction = [UIAlertAction actionWithTitle:filterArray[i] style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action) {
                [self filterSelected:i];
            }];
        
        [alert addAction:filterAction];
    }
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Avbryt" style:UIAlertActionStyleCancel
     handler:nil
   ];
    [alert addAction:cancelAction];

    alert.popoverPresentationController.barButtonItem = _filterButton;
    alert.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:alert animated:YES
                     completion:nil];
}

- (void)filterSelected:(int)buttonIndex
{
    if(buttonIndex == 0)
    {
        [self.filterButton setTintColor:self.buttonTintColor];
    }
    else
    {
        [self.filterButton setTintColor:[UIColor redColor]];
    }
    
    if(self.filter == buttonIndex) // The user pressed cancel or did not change the selection.
        return;

    if(buttonIndex > 14)
        return;
    
    self.filter = (int)buttonIndex;
    [self getWines];
}

- (IBAction)ShowFilterDialog:(id)sender {
    [self ShowFilterDialogEx];
}
- (IBAction)showMenu:(id)sender {
    [self ShowMenuEx];
}

-(void)ShowMenuEx
{
    UIAlertController* alert = [
                                UIAlertController alertControllerWithTitle:nil
                                message:nil
                                preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* helpAction = [UIAlertAction actionWithTitle:@"Hjelp" style:UIAlertActionStyleDefault
         handler:^(UIAlertAction * action) {
             ETHelpViewController *helpController = [self.storyboard instantiateViewControllerWithIdentifier:@"helpViewController"];
             helpController.modalPresentationStyle = UIModalPresentationFullScreen;
             [self presentViewController:helpController animated:YES completion:nil];
         }];
    
    [alert addAction:helpAction];

    UIAlertAction* databaseAction = [UIAlertAction actionWithTitle:@"Database" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * action) {
            [self GetDatabaseDate];
   }];
    
    [alert addAction:databaseAction];

    UIAlertAction* buyAction = [UIAlertAction actionWithTitle:@"Kjøp" style:UIAlertActionStyleDefault
       handler:^(UIAlertAction * action) {
           [self DisplayAlertView:self.usageCounter nag:false];
       }];
    if(_purchased)
    {
        buyAction.enabled = NO;
    }
    [alert addAction:buyAction];


    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Avbryt" style:UIAlertActionStyleCancel
         handler:nil
       ];
    [alert addAction:cancelAction];

    alert.popoverPresentationController.barButtonItem = _menuButton;
    alert.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:alert animated:YES
                     completion:nil];
    
}

-(void)CreateBusyIndicator
{
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat maxWidth = screenBounds.size.width;
    CGFloat maxHeight = screenBounds.size.height;

    CGRect frame = CGRectMake(0,0,maxWidth,maxHeight);
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    [self.activityIndicator setColor:[UIColor redColor]];
    self.activityIndicator.frame = frame;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];
}

- (void)removeArrowsFromSegmentTitleAtIndex:(NSInteger)index
{
    NSString *originalTitle = [self.wineSegment titleForSegmentAtIndex:index];
    
    originalTitle = [originalTitle stringByReplacingOccurrencesOfString:@"▲" withString:@""];
    originalTitle = [originalTitle stringByReplacingOccurrencesOfString:@"▼" withString:@""];
    [self.wineSegment setTitle:originalTitle forSegmentAtIndex:index];
}

- (void)updateSegmentTitleWithArrowAtIndex:(NSInteger)index ascending:(BOOL)ascending {
    [self removeArrowsFromSegmentTitleAtIndex:index];

    NSString *originalTitle = [self.wineSegment titleForSegmentAtIndex:index];

    // Append the correct arrow
    NSString *newTitle = ascending ? [originalTitle stringByAppendingString:@"▲"] : [originalTitle stringByAppendingString:@"▼"];
    [self.wineSegment setTitle:newTitle forSegmentAtIndex:index];
}

- (bool)isSecondaryOrderKeyActive
{
    if(!self.primaryOrderKeyActive)
        return true;
    
    return self.orderBy != self.primaryOrderKey;
}

- (void) setSortDirection
{
    long newSegment = self.wineSegment.selectedSegmentIndex;

    if(newSegment == self.primaryOrderKey && _primaryOrderKeyActive)
    {
        self.primaryOrderAscending = !self.primaryOrderAscending;
    }
    else if(newSegment == self.orderBy)
    {
        self.orderAscending = !self.orderAscending;
    }
    else
    {
        self.orderAscending = true;
    }
}

- (void) updateSortArrows
{
    for(int i = 0; i < self.wineSegment.numberOfSegments; i++)
    {
        if(self.primaryOrderKeyActive && i == self.primaryOrderKey)
        {
            [self updateSegmentTitleWithArrowAtIndex:i ascending:self.primaryOrderAscending];
        }
        else if([self isSecondaryOrderKeyActive] && i == self.orderBy)
        {
            [self updateSegmentTitleWithArrowAtIndex:i ascending:self.orderAscending];
        }
        else
        {
            [self removeArrowsFromSegmentTitleAtIndex:i];
        }
    }
    [self.wineSegment setNeedsLayout];
    [self.wineSegment layoutIfNeeded];
}
- (IBAction)segmentChanged:(id)sender {
    [self setSortDirection];
    self.orderBy = self.wineSegment.selectedSegmentIndex;
    [self updateSortArrows];

    [self getWines];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
        // Open a dialog with more product details?
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

    NSString *s;
    if(wine.type == 11)  {
        s = [NSString stringWithFormat:@"%@ kr.%@ %@ %@ %% %@ kr/liter ", sVinType, wine.price, wine.volume, wine.alcohol, wine.pricePerVolumeUnit];
    }
    else
    {
        s = [NSString stringWithFormat:@"%@ kr.%@ %@ %@%% %@ kr/liter %@ kr/liter alkohol", sVinType, wine.price, wine.volume, wine.alcohol, wine.pricePerVolumeUnit,
                       wine.pricePerAlcoholPerVolumeUnit];
    }
    cell.detailTextLabel.text = s;
    return cell;
}

- (NSMutableString*) GetSearchString
{
    NSMutableString *searchString;
    searchString = [NSMutableString stringWithFormat:@"SELECT \
*,\
CAST(ROUND(price / numeric_volume) AS INTEGER) AS price_per_volume,\
CAST(ROUND(price / ((numeric_volume / 100) * alcohol)) AS INTEGER) AS price_per_alcohol_per_liter \
FROM (SELECT *,\
CAST(REPLACE(REPLACE(SUBSTR(volume, 1, INSTR(volume, ' ') - 1), ',', '.'), ' cl', '') AS REAL) AS numeric_volume FROM VINO "];
                
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
        [searchString appendFormat: @" type=%ld", self.filter-1]; //-1 because 0 means all types in UI.
    }
    [searchString appendString:@")"];

    if(self.primaryOrderKeyActive || [self isSecondaryOrderKeyActive])
    {
        [searchString appendString:@" ORDER BY "];
        
        if(self.primaryOrderKeyActive)
        {
            [searchString appendString:[self getOrderBy:self.primaryOrderKey ascending:self.primaryOrderAscending]];
        }
        if(self.isSecondaryOrderKeyActive)
        {
            if(self.primaryOrderKeyActive)
            {
                [searchString appendString:@","];
            }
            [searchString appendString:[self getOrderBy:self.orderBy ascending:self.orderAscending]];
        }
    }
    
    NSLog(@"%@", searchString);

    return searchString;
}

- (NSString*) getOrderBy:(long)key ascending:(BOOL)ascending
{
    NSMutableString *orderByString = [[NSMutableString alloc] init];
        
    if(key == ORDER_BY_PRICE_PER_ALCOHOL_UNIT)
    {
        if(ascending)
        {
            [orderByString appendString: @" (alcohol = 0) ASC, price_per_alcohol_per_liter ASC"];
        }
        else
        {
            [orderByString appendString: @" (alcohol = 0) ASC, price_per_alcohol_per_liter DESC"];
        }
    }
    else
    {
        if(key == ORDER_BY_NAME)
        {
            [orderByString appendString: @" name"];
        }
        else if(key == ORDER_BY_PRICE)
        {
            [orderByString appendString: @" price"];
        }
        else if(key == ORDER_BY_VOLUME)
        {
            [orderByString appendString: @" numeric_volume"];
        }
        else if(key == ORDER_BY_ALCOHOL_CONTENT)
        {
            [orderByString appendString: @" alcohol"];
        }
        else if(key == ORDER_BY_PRICE_PER_VOLUME_UNIT)
        {
            [orderByString appendString: @" price_per_volume"];
        }
        if(ascending)
        {
            [orderByString appendString: @" ASC"];
        }
        else
        {
            [orderByString appendString: @" DESC"];
        }
    }
    return orderByString;
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
                wine.pricePerVolumeUnit = [results stringForColumn:@"price_per_volume"];
                wine.alcohol = [results stringForColumn:@"alcohol"];
                wine.pricePerAlcoholPerVolumeUnit = [results stringForColumn:@"price_per_alcohol_per_liter"];

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)Get:(NSString*)address
{
    NSURL *url = [NSURL URLWithString:address];
    if(!url)
    {
        [self alertMessage:@"Feil" s:@"Klarte ikke opprette forbindelse til serveren."];
    }
    
    // Create the URLSession with a default configuration
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    
    // Create the data task to fetch the data from the URL
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url];
    
    // Start the data task
    [dataTask resume];
}

- (void) DisplayInternetView
{
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat maxWidth = screenBounds.size.width;
    CGFloat maxHeight = screenBounds.size.height;

    int imgWidth = maxWidth*6/8;
    int imgHeight = maxHeight/2;
    
    self.internetView = [[ETInternetconnection alloc] init:imgWidth imgHeight:imgHeight];
    
    CGRect f = self.internetView.frame;
    f.origin.x = maxWidth/10;
    f.origin.y = imgHeight/2;
    self.internetView.frame = f;
    
    [self.view addSubview:self.internetView];
    NSString *address = @"https://polpriser.github.io/vino13.txt";
    [self.internetView UpdateLabelText:@"Sjekker..."];
    
    [self Get:address];
}
- (IBAction)checkForDatabaseUpdates:(id)sender {
    //This method will call GetDatabaseResult
    [self GetDatabaseDate];
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
    dateFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"nb_NO"];
    NSString *theDate = [dateFormat stringFromDate:dbdate];
    if(self.dateRequestSource == 0)
    {
        NSString* buttonTitle = [NSString stringWithFormat:@"Priser fra %@", theDate];
        self.dbDateButton.title = buttonTitle;
    }
    else
    {
        NSString *msg = [NSString stringWithFormat:@"Din database er fra %@. Vil du undersøke om en nyere er tilgjengelig?", theDate];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Oppdater Database"
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];

        // "Ja" Action
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Ja"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action)
        {
            dispatch_async(dispatch_get_main_queue(),^ {
                [self DisplayInternetView]; // Call the method to display internet view
            } );
        }];

        // "Nei" Action
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"Nei"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil]; // No additional action needed for "Nei"

        [alert addAction:yesAction];
        [alert addAction:noAction];

        [self presentViewController:alert animated:YES completion:nil];
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

- (void)alertMessage:(NSString *)title s:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil]; // The handler is nil because no additional action is needed.
    [alert addAction:okAction];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark NSURLConnection Delegate Methods
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"Received response: %@", response.URL);

    // Initialize your response data and reset bytesReceived
    self.responseData = [[NSMutableData alloc] init];
    self.bytesReceived = 0;

    // Allow the session to continue
    completionHandler(NSURLSessionResponseAllow);
}


- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    self.bytesReceived += data.length;
    [self.responseData appendData:data];

    NSLog(@"Current thread: %@", [NSThread currentThread]);

    // Update UI on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *status = [NSString stringWithFormat:@"Mottar data: %ld bytes", self.bytesReceived];
        [self.internetView UpdateLabelText:status];
    });
}

- (void)URLSession:(NSURLSession *)session
  task:(NSURLSessionTask *)task
  didCompleteWithError:(NSError *)error {
    if (error) {
        // Handle the error
        NSLog(@"Internet connection error: %@", error.description);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.internetView removeFromSuperview];
            [self alertMessage:@"Feil" s:error.localizedDescription];
        });
    } else {
        NSLog(@"Internet connection finish.");
        if (self.downloadState == 0) {
            NSLog(@"Current thread: %@", [NSThread currentThread]);

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.internetView UpdateLabelText:@""];
                [self displayDownloadDialog];
            });
        } else {
            self.downloadState = 0;

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.internetView UpdateLabelText:@"Lagrer database"];
            });

            NSString *databasePath = [Utility getDatabasePath];

            BOOL success = [self.responseData writeToFile:databasePath atomically:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.internetView removeFromSuperview];
                if (success) {
                    [self.queue close];
                    self.queue = [FMDatabaseQueue databaseQueueWithPath:databasePath];

                    // Perform database-related updates
                    [self getWines];
                    self.dateRequestSource = 0;
                    [self GetDatabaseDate];
                    self.dateRequestSource = 1;

                    [self UpdateUsageCounterInDatabase];

                    [self alertMessage:@"Database" s:@"Du har nå den nyeste utgaven av databasen."];
                } else {
                    [self alertMessage:@"Database" s:@"Klarte ikke å lagre den nye databasen."];
                }
            });
        }
    }
}

- (void)displayDownloadDialog {
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
        
        [dateFormat setDateStyle:NSDateFormatterMediumStyle];
        dateFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"nb_NO"];
        NSString *newDate = [dateFormat stringFromDate:newdbdate];
        NSString *currentDate = [dateFormat stringFromDate:currentdbdate];
        
        NSString *msg = [NSString stringWithFormat:@"Din database er fra %@. En database fra %@ er tilgjengelig. Vil du laste den ned?", currentDate, newDate];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Database"
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        // "Ja" Action
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Ja"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
            self.downloadState = 1;
            NSString *address = @"https://polpriser.github.io/vino13.db";
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.internetView UpdateLabelText:@"Laster ned..."];
            });
            
            [self Get:address];
        }];
        
        // "Nei" Action
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"Nei"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
            [self.internetView removeFromSuperview];
        }];
        
        [alert addAction:yesAction];
        [alert addAction:noAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void) save
{
    // Store the data
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:self.primaryOrderKeyActive forKey:@"primaryOrderKeyActive"];
    [defaults setBool:self.primaryOrderAscending forKey:@"primaryOrderAscending"];
    [defaults setInteger:self.primaryOrderKey forKey:@"primaryOrderKey"];

    [defaults setBool:self.orderAscending forKey:@"orderAscending"];
    [defaults setInteger:self.orderBy forKey:@"orderBy"];
    [defaults setInteger:self.filter forKey:@"filter"];

    [defaults synchronize];
    
    NSLog(@"Data saved");
}

- (void)load
{
    // Get the stored data before the view loads
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:@"primaryOrderKeyActive"] != nil)
    {
        self.primaryOrderKeyActive = [defaults boolForKey:@"primaryOrderKeyActive"];
    }
    if ([defaults objectForKey:@"primaryOrderAscending"] != nil)
    {
        self.primaryOrderAscending = [defaults boolForKey:@"primaryOrderAscending"];
    }
    if ([defaults objectForKey:@"primaryOrderKey"] != nil)
    {
        self.primaryOrderKey = [defaults integerForKey:@"primaryOrderKey"];
    }

    if ([defaults objectForKey:@"orderAscending"] != nil)
    {
        self.primaryOrderKeyActive = [defaults boolForKey:@"orderAscending"];
    }
    if ([defaults objectForKey:@"orderBy"] != nil)
    {
        self.orderBy = [defaults integerForKey:@"orderBy"];
    }
    if ([defaults objectForKey:@"filter"] != nil)
    {
        self.filter = [defaults integerForKey:@"filter"];
    }
}


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
/*    if([segue.identifier  isEqual: @"WineDetails"])
    {
        NSIndexPath *indexPath = [self.wineTableView indexPathForSelectedRow];
        ETStockViewController *destViewController = segue.destinationViewController;
        Wine *wine;
        wine = [self.fullWineList objectAtIndex:indexPath.row];
        destViewController.sku = wine.id;
    }
 */
}


@end
