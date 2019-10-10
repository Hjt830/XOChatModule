//
//  XOLocationViewController.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/10/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <XOBaseLib/XOBaseLib.h>
#import <CoreLocation/CoreLocation.h>

@class XOLocationViewController;
@protocol XOLocationViewControllerDelegate <NSObject>

@optional
- (void)locationViewController:(XOLocationViewController *)locationViewController pickLocationLatitude:(double)latitude longitude:(double)longitude addressDesc:(NSString *)address;
@end


typedef NS_ENUM(NSUInteger, XOLocationType) {
    XOLocationTypeSend,     // 发送定位
    XOLocationTypeRecive,   // 查看定位
};


@interface XOLocationViewController : XOBaseViewController

@property (nonatomic, assign) XOLocationType locationType;

@property (nonatomic, assign) CLLocationCoordinate2D location;  // XOLocationTypeRecive 时必传
@property (nonatomic, copy) NSString *address;                  // XOLocationTypeRecive 时传

@property (nonatomic, assign) id <XOLocationViewControllerDelegate> delegate;

@end




@interface POITableViewCell : UITableViewCell

@property (nonatomic, copy) NSString               *POIName;
@property (nonatomic, copy) NSString               *addressName;

@end
