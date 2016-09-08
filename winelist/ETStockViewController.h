//
//  ETStockViewController.h
//  Polet prisliste
//
//  Created by Erlend Thune on 11.09.15.
//  Copyright (c) 2015 Erlend Thune. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETStockViewController : UIViewController
@property (nonatomic, strong) NSString *url;
@property int sku;
@property (weak, nonatomic) IBOutlet UIWebView *stockWebView;

@end
