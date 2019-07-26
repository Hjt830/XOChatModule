//
//  JTBaseNavigationController.m
//  JTMainProject
//
//  Created by kenter on 2019/6/5.
//  Copyright © 2019 KENTER. All rights reserved.
//

#import "JTBaseNavigationController.h"

@implementation JTBaseNavigationController
    
+ (void)initialize
{
    [[UINavigationBar appearance] setBarStyle:UIBarStyleDefault];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor],
                                                           NSFontAttributeName: [UIFont boldSystemFontOfSize:19.0f]}];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
//    self.delegate = viewController;
    [super pushViewController:viewController animated:animated];
}
    
- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    return [super popViewControllerAnimated:animated];
}

@end
