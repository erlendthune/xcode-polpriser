//
//  IAPHelper.m
//  HeartMonitor
//
//  Created by Erlend Thune on 29.06.15.
//  Copyright (c) 2015 Razeware LLC. All rights reserved.
//

#import "IAPHelper.h"
#import <StoreKit/StoreKit.h>

NSString *const IAPHelperProductPurchasedNotification = @"IAPHelperProductPurchasedNotification";
NSString *const IAPHelperProductPurchasedError = @"IAPHelperProductPurchasedError";
NSString *const IAPHelperProductAlreadyPurchased = @"IAPHelperProductAlreadyPurchased";
NSString *const IAPHelperProductRestorePurchaseError = @"IAPHelperProductRestorePurchaseError";
NSString *const IAPHelperTransactionFinished = @"IAPHelperTransactionFinished";

// 2
@interface IAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

@implementation IAPHelper {
    // 3
    SKProductsRequest * _productsRequest;
    // 4
    RequestProductsCompletionHandler _completionHandler;
    NSSet * _productIdentifiers;
    NSMutableSet * _purchasedProductIdentifiers;
}


- (void)validateReceipt: (ETViewController*) mvc
{
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSURL *receiptURL = [mainBundle appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
    if (!receipt) {
        /* No local receipt -- handle the error. */
        NSLog(@"validateReceipt:Could not find receipt.");
        [mvc AppNotPurchased];
        return ;
    }

    // Create the JSON object that describes the request
    NSError *error;
    NSDictionary *requestContents = @{
                                      @"receipt-data": [receipt base64EncodedStringWithOptions:0]
                                      };
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents
                                                          options:0
                                                            error:&error];
    
    if (!requestData) {
        /* ... Handle error ... */
        NSLog(@"validateReceipt:Could not find receipt data.");
        [mvc AppNotPurchased];
        return;
    }
    
    // Create a POST request with the receipt data.
#ifdef DEBUG
    NSURL *storeURL = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
#else
    NSURL *storeURL = [NSURL URLWithString:@"https://buy.itunes.apple.com/verifyReceipt"];
#endif
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    
    // Make a connection to the iTunes Store on a background queue.
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:storeRequest queue:queue
       completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
       if (connectionError)
       {
           NSLog(@"alidateReceipt:Failed to communicate with apple server.");
           [mvc AppNotPurchased];
           return;
       }
       else
       {
           NSError *error;
           NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
           if (!jsonResponse)
           {
               /* ... Handle error ...*/
               NSLog(@"alidateReceipt:Failed to obtain response.");
               [mvc AppNotPurchased];
               return;
           }
           else
           {
               NSString *datePurchasedString = jsonResponse[@"receipt"][@"original_purchase_date"];
               NSLog(@"alidateReceipt:Found date purchased:%@", datePurchasedString);
               
               datePurchasedString = [datePurchasedString stringByReplacingOccurrencesOfString:@"Etc/GMT" withString:@"GMT"];
               NSDateFormatter *dateFormat=[[NSDateFormatter alloc] init];
               [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss z"];
               NSDate *datePurchased = [dateFormat dateFromString:datePurchasedString];

               if(datePurchased)
               {
                   //The app was free after this date.
#ifdef DEBUG
                   NSString *dateStr = @"20101229";
#else
                   NSString *dateStr = @"20171229";
#endif
                   // Convert string to date object
                   [dateFormat setDateFormat:@"yyyyMMdd"];
                   NSDate *dateWhenFremium = [dateFormat dateFromString:dateStr];
                   time_t secondsWhenFremium = [dateWhenFremium timeIntervalSince1970];
                   time_t secondsWhenPurchased = [datePurchased timeIntervalSince1970];

                   if(secondsWhenPurchased < secondsWhenFremium)
                   {
                       [mvc AppPurchased];
                   }
                   else
                   {
                       [mvc AppNotPurchased];
                   }
               }
           }
       }
   }];
}
// Add new method
- (void)storePurchase:(NSString*)productIdentifier
{
    [_purchasedProductIdentifiers addObject:productIdentifier];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];

}
- (void)provideContentForProductIdentifier:(NSString *)productIdentifier {
    [self storePurchase:productIdentifier];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchasedNotification object:productIdentifier userInfo:nil];
}
- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    
    if ((self = [super init])) {
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products
        _purchasedProductIdentifiers = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers) {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
            if (productPurchased) {
                [_purchasedProductIdentifiers addObject:productIdentifier];
                NSLog(@"Previously purchased: %@", productIdentifier);
            } else {
                NSLog(@"Not purchased: %@", productIdentifier);
            }
        }
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}


- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment
          forProduct:(SKProduct *)product
{
    if([self productPurchased:@"com.erlendthune.polpriser"])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchasedError object:nil userInfo:nil];

        return false;
    }
    else
    {
        return true;
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    NSLog(@"paymentQueue");
    for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                NSLog(@"paymentQueue:SKPaymentTransactionStatePurchased");
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"paymentQueue:SKPaymentTransactionStateFailed");
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"paymentQueue:SKPaymentTransactionStateRestored");
                [self restoreTransaction:transaction];
            default:
                NSLog(@"paymentQueue:default");
                break;
        }
    };
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"completeTransaction...");
    
    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"restoreTransaction...");
    
    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    NSLog(@"failedTransaction...");
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductPurchasedError object:nil userInfo:nil];
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler {
    NSLog(@"requestProductsWithCompletionHandler");

    // 1
    _completionHandler = [completionHandler copy];
    
    // 2
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productsRequest.delegate = self;
    [_productsRequest start];
    
}

- (BOOL)productPurchased:(NSString *)productIdentifier {
    NSLog(@"productPurchased");
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}

- (void)paymentQueue:(SKPaymentQueue *)queue
 removedTransactions:(NSArray *)transactions
{
    NSLog(@"removedTransactions");
}
- (void)restoreCompletedTransactions {
    NSLog(@"restoreCompletedTransactions");
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}
- (bool)buyProduct:(SKProduct *)product {
    bool canMakePayments = [SKPaymentQueue canMakePayments];
    
    NSLog(@"Buying %@...", product.productIdentifier);
    
    if(canMakePayments)
    {
        SKPayment * payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        return true;
    }
    return canMakePayments;
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    NSLog(@"Loaded list of products...");
    _productsRequest = nil;
    
    NSArray * skProducts = response.products;
    for (SKProduct * skProduct in skProducts) {
        NSLog(@"Found product: %@ %@ %0.2f",
              skProduct.productIdentifier,
              skProduct.localizedTitle,
              skProduct.price.floatValue);
    }
    
    
    _completionHandler(YES, skProducts);
    _completionHandler = nil;
    
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperTransactionFinished object:nil userInfo:nil];
}

- (void)paymentQueue:(SKPaymentQueue *)queue
restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"restoreCompletedTransactionsFailedWithError:%@", error.description);
    [[NSNotificationCenter defaultCenter] postNotificationName:IAPHelperProductRestorePurchaseError object:nil userInfo:nil];
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    NSLog(@"Failed to load list of products: %@", error.description);
    _productsRequest = nil;
    
    _completionHandler(NO, nil);
    _completionHandler = nil;
    
}
@end
