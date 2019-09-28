//
//  XOChatAppDelegate.m
//  XOChatModule
//
//  Created by kenter on 07/03/2019.
//  Copyright (c) 2019 kenter. All rights reserved.
//

#import "XOChatAppDelegate.h"
#import <XOBaseLib/XOBaseLib.h>
#import <XOChatModule/XOChatModule.h>

#import "XOConversationListController.h"
#import "XODetailViewController.h"

#define TXTIMAppID      @"1400079944"

#if 0

// 13229292929
#define Token           @"ac7295f5e92742dea25260e9a780db91"
#define TIM_UserId      @"20f63beb2dd9432393c494c7baf4aad1"
#define TIM_UserSig     @"eJw1kF1PgzAUhv8L18YwWtrVxAsCxCx2yr5KvCL9JFU7K3YRZvzvMmS3z3NO3nPen2hPd7fce6saHhrQqeguiqObCeve20433ATdjThJSRLHV2mVPgZr7L*KDQJCi0QpAkECCJCQQIkFN5BztZh3vmw7Dq-LQ77aFHlhJM0wUmdmUP4o6if6un0QrHL9idaVt8i9cE2H6tyu2vKTvYOs9j487zNhcN6WRaolGgjRgB1St-l2ku22PV3fX8PUWzM9NkYu4Hg4JgTCWQbr9IWnaLnEyahmzqX8OB1DEwavpyZ*-wBS-1fR"

#else

// 13225252525
#define Token           @"0db1788e4d7e44adb7ccd8dfd6dfdf6c"
#define TIM_UserId      @"fddd69261dc44ebe928bc81ebc5bf1a7"
#define TIM_UserSig     @"eJw1kF1vgjAUhv8L18soXUG6xAtBQlxcbJ1xuhvSj1NXlzEGZeiM-32MyO3znJP3nPfibZYv96KqrC6EKx5q7T16yLsbMJwqW0MhjIO6xzikGKFRWg2ls8YOymitI4qjQCtCQALFsVRxAFKF0gRicttp7KEffs54usg3-tv7Mc1r5li7WpJWrdaq092**T2ZLPHzn3kjfG22bD2zSSIQzdhOvoa8nH8zivkW*HkHR44WNj3wALXoaRbnjnfT6RimP4rhsT4yIP3hE0oJuUlnP*GfhxElMaF45EKpr7Z0hTtXMDRx-QOoule8"

#endif

@interface XOChatAppDelegate () <TIMConnListener, UISplitViewControllerDelegate>

@end

@implementation XOChatAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[XOSettingManager defaultManager] setAppLanguage:XOLanguageNameZh_Hant];
    
    NSString *str = XOLocalizedString(@"NSDateCategory.text8");
    NSLog(@"str: %@", str);
    
    // 1、初始化腾讯云通信
    [[XOChatClient shareClient] initSDKWithAppId:[TXTIMAppID intValue] logFun:^(TIMLogLevel lvl, NSString *msg) {
        
        NSLog(@"=================================");
        NSLog(@"=========== 云通信日志 ============");
        NSLog(@"=================================");
        NSLog(@"=========== TIM msg: %@", msg);
        NSLog(@"=================================");
        NSLog(@"=================================\n");
    }];
    
    // 2、登录腾讯云通信
    TIMLoginParam *loginParam = [[TIMLoginParam alloc] init];
    loginParam.identifier = TIM_UserId;
    loginParam.userSig = TIM_UserSig;
    loginParam.appidAt3rd = TIM_UserId;
    [[XOChatClient shareClient] loginWith:loginParam successBlock:^{
        
        NSLog(@"============ 云通信登录成功 ================");
    } failBlock:^(int code, NSString *msg) {
        
        NSLog(@"============ 云通信登录失败 ================");
    }];
    [XOKeyChainTool saveAppUserName:TIM_UserId password:@"123456"];
    
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, KWIDTH, KHEIGHT)];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    XOConversationListController *chatListVC = [[XOConversationListController alloc] init];
    
#if  0
    chatListVC.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMostViewed tag:0];
    
    UIViewController *secondVC = [[UIViewController alloc] init];
    secondVC.view.backgroundColor = [UIColor whiteColor];
    secondVC.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemContacts tag:1];
    
    UIViewController *thirdVC = [[UIViewController alloc] init];
    thirdVC.view.backgroundColor = [UIColor whiteColor];
    thirdVC.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemTopRated tag:2];
    
    UIViewController *fouthVC = [[UIViewController alloc] init];
    fouthVC.view.backgroundColor = [UIColor whiteColor];
    fouthVC.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemBookmarks tag:2];
    
    UITabBarController *tabbarVC = [[UITabBarController alloc] init];
    tabbarVC.viewControllers = @[chatListVC, secondVC, thirdVC, fouthVC];
    XOBaseNavigationController *masterNav = [[XOBaseNavigationController alloc] initWithRootViewController:tabbarVC];
    
    XODetailViewController *detailVC = [[XODetailViewController alloc] init];
    
    UISplitViewController *splitViewController = [[UISplitViewController alloc] init];
    splitViewController.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    splitViewController.preferredPrimaryColumnWidthFraction = 0.5;
    splitViewController.maximumPrimaryColumnWidth = 414.0;
    splitViewController.delegate = self;
    [splitViewController addChildViewController:masterNav];
    [splitViewController addChildViewController:detailVC];
    
    self.window.rootViewController = splitViewController;
    
#else
    
    XOBaseNavigationController *masterNav = [[XOBaseNavigationController alloc] initWithRootViewController:chatListVC];
    self.window.rootViewController = masterNav;
    
#endif
    
    // 初始化表情包
    [[ChatFaceHelper sharedFaceHelper] initilizationEmoji];
    
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

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    return YES;
}

//- (nullable UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController
//{
//    if ([primaryViewController isKindOfClass:[XOBaseNavigationController class]]) {
//        return primaryViewController;
//    }
//    return nil;
//}

//- (nullable UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController
//{
//    if ([primaryViewController isKindOfClass:[XOBaseNavigationController class]]) {
//        return primaryViewController;
//    }
//    return nil;
//}

//- (nullable UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController
//{
//    return splitViewController.viewControllers[0];
//}

@end
