//
//  ForwardView.h
//  xxoogo
//
//  Created by kenter on 2019/6/12.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import <XOBaseLib/XOBaseLib.h>
#import <ImSDK/ImSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class ForwardView;
@protocol ForwardViewDelegate <NSObject>

@optional
- (void)forwardView:(ForwardView *)forwardView forwardMessage:(TIMMessage *)message toReceivers:(NSArray *)receivers;
- (void)forwardViewDidCancelForward:(ForwardView *)forwardView;

@end

@interface ForwardView : UIView

@property (nonatomic, weak) id   <ForwardViewDelegate> delegate;

- (void)showInView:(UIView *)view withReceivers:(NSArray *)receivers message:(TIMMessage *)message delegate:(id <ForwardViewDelegate>)delegate;

@end




@interface ForwardContentView : UIView

@property (nonatomic, assign) float      lineHeight;
@property (nonatomic, assign) BOOL       isImage;

@end

NS_ASSUME_NONNULL_END
