//
//  ForwardView.h
//  xxoogo
//
//  Created by kenter on 2019/6/12.
//  Copyright © 2019 xinchidao. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ForwardView;
@protocol ForwardViewDelegate <NSObject>

@optional
- (void)forwardToSomeOneDidSure:(ForwardView *)forwardView;
- (void)forwardToSomeOneDidCancel:(ForwardView *)forwardView;

@end

@interface ForwardView : UIView

@property (nonatomic, weak) id   <ForwardViewDelegate> delegate;

- (void)showInView:(UIView *)view withReceivers:(NSArray <IMAUser *>*)receivers message:(IMAMsg *)message delegate:(id <ForwardViewDelegate>)delegate;

@end




@interface ForwardContentView : UIView

@property (nonatomic, assign) float      lineHeight;
@property (nonatomic, assign) BOOL       isImage;

@end

NS_ASSUME_NONNULL_END
