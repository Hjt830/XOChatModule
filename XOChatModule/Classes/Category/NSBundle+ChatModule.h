//
//  NSBundle+ChatModule.h
//  XOChatModule_Example
//
//  Created by kenter on 2019/8/13.
//  Copyright © 2019 kenter. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define XOChatLocalizedString(key) ([NSBundle chat_localizedStringForKey:(key)])

@interface NSBundle (ChatModule)

+ (NSBundle *)xo_chatBundle;
+ (NSString *)chat_localizedStringForKey:(NSString *)key value:(NSString *)value;
+ (NSString *)chat_localizedStringForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
