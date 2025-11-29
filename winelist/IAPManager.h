/*
//
//  IAPManager.h
//  Polpriser
//
//  Created by Erlend Thune on 25/01/2025.
//  Copyright © 2025 Erlend Thune. All rights reserved.
//

#ifndef IAPManager_h
#define IAPManager_h

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "ETViewController.h"

@interface IAPManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, weak) ETViewController *mvc;

+ (instancetype)sharedManager;
- (void)configureWithViewController:(ETViewController *)mvc;
- (void)fetchProducts;
- (void)purchaseProduct;
- (void)restorePurchases;


@end

#endif*/
 /* IAPManager_h */
