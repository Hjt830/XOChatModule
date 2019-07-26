//
//  XOChatAppDelegate.m
//  XOChatModule
//
//  Created by kenter on 07/03/2019.
//  Copyright (c) 2019 kenter. All rights reserved.
//

#import "XOChatAppDelegate.h"
#import "XOChatListViewController.h"

#import <JTBaseLib/JTBaseLib.h>
#import "XOChatClient.h"

#define TXTIMAppID      @"1400213643"
#define TIM_UserId      @"IM_User_1"
#define TIM_UserSig     @"eJxlj11LwzAARd-7K0qfRdKm6bLBHkKsrrhN3dYJfQllSbpM*mGatXXifxfrwID39Rzu5X46rut6u*X2Nj8c6nNlmPlohOfOXA94N3*waRRnuWFQ839QDI3SguXSCD1CHyEUAGA7iovKKKmuRrJiaSs08y2l5W9s3PntCAEIfBiF0FZUMcJV-EKTWNLkOaZpuiAZofctLk0pIV*Dcgjx6bW-LPdU9adsKx6JIjVZ9Pun6d3GZEM-mYYP7xE9R2tJhqLTXXXhO9h18JjEx2I*tyaNKsX1VBSgCcAYW7QTulV1NQoB8JEfQPATz-lyvgHBtV7d"

@interface XOChatAppDelegate () <TIMConnListener>

@end

@implementation XOChatAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // 1、初始化腾讯云通信
    [[XOChatClient shareClient] initSDKWithAppId:[TXTIMAppID intValue] logFun:^(TIMLogLevel lvl, NSString *msg) {
        
        NSLog(@"=================================");
        NSLog(@"=========== 云通信日志 ============");
        NSLog(@"=================================");
        NSLog(@"=========== TIM msg: %@", msg);
        NSLog(@"=================================");
        NSLog(@"=================================\n");
        
    } connListener:self];
    
    // 2、登录腾讯云通信
    TIMLoginParam *loginParam = [[TIMLoginParam alloc] init];
    loginParam.identifier = TIM_UserId;
    loginParam.userSig = TIM_UserSig;
    loginParam.appidAt3rd = TIM_UserId;
    [[XOChatClient shareClient] loginWith:loginParam successBlock:nil failBlock:nil];
    
    [NSThread sleepForTimeInterval:3];
    
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, KWIDTH, KHEIGHT)];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    XOChatListViewController *chatListVC = [[XOChatListViewController alloc] initWithStyle:UITableViewStyleGrouped];
    JTBaseNavigationController *nav = [[JTBaseNavigationController alloc] initWithRootViewController:chatListVC];
    
    self.window.rootViewController = nav;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}



#pragma mark ========================= TIMConnListener =========================

/**
 *  网络连接成功
 */
- (void)onConnSucc
{
    NSLog(@"\n=======************======= TIM 网络连接成功");
}

/**
 *  网络连接失败
 *
 *  @param code 错误码
 *  @param err  错误描述
 */
- (void)onConnFailed:(int)code err:(NSString*)err
{
    NSLog(@"\n=======************======= TIM 网络连接失败 code: %d err:%@", code, err);
}

/**
 *  网络连接断开（断线只是通知用户，不需要重新登陆，重连以后会自动上线）
 *
 *  @param code 错误码
 *  @param err  错误描述
 */
- (void)onDisconnect:(int)code err:(NSString*)err
{
    NSLog(@"\n=======************======= TIM 网络连接断开 code: %d err:%@", code, err);
}

@end
