//
//  Customer.h
//  Chanda
//
//  Created by Mohammad Azam on 10/25/11.
//  Copyright (c) 2011 HighOnCoding. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Wine : NSObject
{
    
}

@property (nonatomic,assign) int id;
@property (nonatomic,assign) int type;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *href;
@property (nonatomic,strong) NSString *volume;
@property (nonatomic,assign) int price;
@property (nonatomic,assign) int oldprice;
@property (nonatomic,assign) float pricechange;

@end
