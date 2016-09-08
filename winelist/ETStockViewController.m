//
//  ETStockViewController.m
//  Polet prisliste
//
//  Created by Erlend Thune on 11.09.15.
//  Copyright (c) 2015 Erlend Thune. All rights reserved.
//

#import "ETStockViewController.h"

@interface ETStockViewController ()

@end

@implementation ETStockViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *thePath = [NSString stringWithFormat:@"%@?ShowShopsWithProdInStock=true&sku=%d&fylke_id=*",
                         _url,_sku];
    
    
    if (thePath)
    {
        [self.stockWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:thePath isDirectory:NO]]];
    }
}

#pragma mark - Navigation


@end
