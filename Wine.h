#import <Foundation/Foundation.h>

@interface Wine : NSObject
{
    
}

@property (nonatomic,assign) int id;
@property (nonatomic,assign) int type;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *volume;
@property (nonatomic,strong) NSString *price;
@property (nonatomic,strong) NSString *alcohol;
@property (nonatomic,strong) NSString *pricePerVolumeUnit;
@property (nonatomic,strong) NSString *pricePerAlcoholPerVolumeUnit;
@end
