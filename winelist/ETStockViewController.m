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
- (IBAction)vinDone:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewDidLoad
{
    [super viewDidLoad];
//    NSString *fullURL = @"https://apple.com";
    NSString *fullURL = [NSString stringWithFormat:@"https://www.vinmonopolet.no/vmpSite/p/%d",_sku];
    NSURL *url = [NSURL URLWithString:fullURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.stockWebView loadRequest:requestObj];
}

#pragma mark - Navigation


@end
