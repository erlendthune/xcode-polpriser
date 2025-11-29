//
//  IAPLocalizedPrice.m
//  Polpriser
//
//  Created by Erlend Thune on 25/01/2025.
//  Copyright © 2025 Erlend Thune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SKProduct (LocalizedPrice)
@property (nonatomic, readonly) NSString *localizedPrice;
@end

@implementation SKProduct (LocalizedPrice)
- (NSString *)localizedPrice {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.locale = self.priceLocale;
    return [formatter stringFromNumber:self.price];
}
@end
