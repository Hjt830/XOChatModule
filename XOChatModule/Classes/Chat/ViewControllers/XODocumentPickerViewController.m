//
//  XODocumentPickerViewController.m
//  AFNetworking
//
//  Created by kenter on 2019/9/19.
//

#import "XODocumentPickerViewController.h"

@interface XODocumentPickerViewController ()

@property (nonatomic, strong) UIColor               *originColor;

@end

@implementation XODocumentPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSDictionary *attributes = [[UIBarButtonItem appearance] titleTextAttributesForState:UIControlStateNormal];
    self.originColor = [attributes valueForKey:NSForegroundColorAttributeName];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor greenColor]} forState:UIControlStateNormal];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    UIColor *originColor = (nil == self.originColor) ? [UIColor whiteColor] : self.originColor;
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: originColor} forState:UIControlStateNormal];
}

@end
