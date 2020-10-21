//
//  IAPHelper.h
//  HeartMonitor
//
//  Created by Erlend Thune on 29.06.15.
//  Copyright (c) 2015 Razeware LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "ETViewController.h"

UIKIT_EXTERN NSString *const IAPHelperProductPurchasedNotification;
UIKIT_EXTERN NSString *const IAPHelperProductPurchasedError;
UIKIT_EXTERN NSString *const IAPHelperProductAlreadyPurchased;
UIKIT_EXTERN NSString *const IAPHelperProductRestorePurchaseError;
UIKIT_EXTERN NSString *const IAPHelperTransactionFinished;

typedef void (^RequestProductsCompletionHandler)(BOOL success, NSArray * products);

@interface IAPHelper : NSObject

- (void)storePurchase:(NSString*)productIdentifier;
- (void)validateReceipt:(ETViewController*) mvc;
- (void)provideContentForProductIdentifier:(NSString *)productIdentifier;
- (bool)buyProduct:(SKProduct *)product;
- (BOOL)productPurchased:(NSString *)productIdentifier;
- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
- (void)restoreCompletedTransactions;
@end
