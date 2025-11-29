#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SKProduct (LocalizedPrice)

/// A localized string representing the product's price, formatted for the user's current locale.
@property (nonatomic, readonly) NSString *localizedPrice;

@end
