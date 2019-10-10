//
//  ZFLocationViewController.h
//  HTMessage
//
//  Created by Lucas.Xu on 2017/12/8.
//  Copyright © 2017年 Hefei Palm Peak Technology Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ZFLocationViewControllerDelegate <NSObject>

@optional
- (void)sendLocationLatitude:(double)latitude longitude:(double)longitude andAddress:(NSString *)address andAddressSnapshotImage:(NSData *)imageData imageSize:(CGSize)size andName:(NSString *)name;
@end


typedef NS_ENUM(NSUInteger, WXLocationType) {
    WXLocationTypeSend,     // 发送定位
    WXLocationTypeRecive,   // 查看定位
};


@interface ZFLocationViewController : WXBaseViewController

@property (nonatomic, assign) WXLocationType locationType;

@property (nonatomic, assign) CLLocationCoordinate2D location;  // WXLocationTypeRecive 时必传
@property (nonatomic, copy) NSString *address;                  // WXLocationTypeRecive 时传

@property (nonatomic, assign) id <ZFLocationViewControllerDelegate> delegate;

@end
