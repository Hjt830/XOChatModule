//
//  ZFLocationViewController.m
//  HTMessage
//
//  Created by Lucas.Xu on 2017/12/8.
//  Copyright © 2017年 Hefei Palm Peak Technology Co., Ltd. All rights reserved.
//

#import "ZFLocationViewController.h"
#import "POITableViewCell.h"
#import "MJRefresh.h"

#import <MAMapKit/MAMapKit.h>
#import <MapKit/MapKit.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

#define MapHeight KHEIGHT * (300.0/667.0)
static NSString * const POITableViewCellID = @"POITableViewCellID";
static NSString * const PointReuseIndentifier = @"pointReuseIndentifier";

@interface ZFLocationViewController ()<UISearchControllerDelegate,UISearchResultsUpdating,MAMapViewDelegate,AMapLocationManagerDelegate,AMapSearchDelegate,UITableViewDelegate,UITableViewDataSource, CLLocationManagerDelegate>

@property (nonatomic, strong)UITableView        *tableView;
@property (nonatomic ,strong)UITableView        *searchTableView;//用于搜索的tableView
@property (nonatomic, strong)UISearchController *searchController;
@property (nonatomic, strong)MAMapView          *mapView;
@property (nonatomic, strong)UIButton           *locationBtn;

@property (nonatomic, strong)UIView             *bottomView;
@property (nonatomic, strong)UILabel            *addressLabel;
@property (nonatomic, strong)UIButton           *navigationBtn;

@property (nonatomic ,assign)NSInteger          currentPage;
@property (nonatomic ,assign)BOOL               isSelectedAddress;
@property (nonatomic ,strong)NSIndexPath        *selectedIndexPath;

@property (nonatomic, strong)NSString           *addressString;
@property (nonatomic ,strong)NSString           *city;//定位的当前城市，用于搜索功能

@property (nonatomic,strong)NSArray             *dataArray;
@property (nonatomic ,strong)NSArray            *tipsArray;//搜索提示的数组

@property (nonatomic ,strong)AMapPOIAroundSearchRequest *request;
@property (nonatomic, strong)AMapLocationManager        *locationManager;
@property (nonatomic,strong)AMapSearchAPI               *mapSearch;
@property (nonatomic ,strong)AMapPOI                    *currentPOI;//点击选择的当前的位置插入到数组中
@property (nonatomic, assign)CLLocationCoordinate2D     currentLocationCoordinate;
@property (nonatomic, assign)CLLocationCoordinate2D     startLocation;

@end

@implementation ZFLocationViewController

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (WXLocationTypeSend == self.locationType) {
        self.searchController.searchBar.frame = CGRectMake(0, 0, KWIDTH, 44);
        self.mapView.frame = CGRectMake(0, 44, KWIDTH, MapHeight);
        self.tableView.frame = CGRectMake(0, (MapHeight + 44), KWIDTH, self.view.height - MapHeight - 44);
    } else {
        self.mapView.frame = CGRectMake(0, 0, KWIDTH, self.view.height - 64);
        self.bottomView.frame = CGRectMake(0, self.view.height - 64, KWIDTH, 64);
        self.navigationBtn.frame = CGRectMake(KWIDTH - 20 - 50, 7, 50, 50);
        self.addressLabel.frame = CGRectMake(20, 17, KWIDTH - 110, 30);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"定位";
    
    [self initilization];
    
    [self setupSubViews];
    
    if (![CLLocationManager locationServicesEnabled] ||
        kCLAuthorizationStatusAuthorizedAlways != [CLLocationManager authorizationStatus] ||
        kCLAuthorizationStatusAuthorizedWhenInUse != [CLLocationManager authorizationStatus]) {
        // 申请定位权限
        CLLocationManager *manager = [[CLLocationManager alloc] init];
        manager.delegate = self;
        [manager requestWhenInUseAuthorization];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (WXLocationTypeSend == self.locationType) {
        // 定位
        [self locateAction];
    }
    else {
        [self showMapPoint];
        [self setCenterPoint];
    };
}

- (void)initilization
{
    if (WXLocationTypeSend == self.locationType) {
        self.isSelectedAddress = NO;
        self.currentPage = 1;
        self.selectedIndexPath = [NSIndexPath indexPathForRow:-1 inSection:-1];
    } else {
        self.addressLabel.text = self.address;
    }
}

- (void)setupSubViews
{
    self.definesPresentationContext = YES;
    
    [self.view addSubview:self.mapView];
    
    if (WXLocationTypeSend == self.locationType) {
        
        [self setupNav];
        
        [self.mapView addSubview:self.locationBtn];
        
        [self.view addSubview:self.tableView];
        
        [self.view addSubview:self.searchController.searchBar];
    }
    else {
        [self.view addSubview:self.bottomView];
        
        [self.bottomView addSubview:self.addressLabel];
        
        [self.bottomView addSubview:self.navigationBtn];
    }
}

- (void)setupNav
{
    UIButton *sendButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    [sendButton setTitle:NSLocalizedString(@"send", @"Send") forState:UIControlStateNormal];
    [sendButton setTitleColor:BASE_GREEN_COLOR forState:UIControlStateNormal];
    sendButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [sendButton addTarget:self action:@selector(sendLocation) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    UIBarButtonItem *sendItem = [[UIBarButtonItem alloc] initWithCustomView:sendButton];
    
    UIBarButtonItem *nagativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    nagativeSpacer.width = -10;
    [self.navigationItem setRightBarButtonItems:@[nagativeSpacer,sendItem]];
}

#pragma mark ====================== lazy =======================

- (AMapLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[AMapLocationManager alloc] init];
        [_locationManager setDelegate:self];
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
        [_locationManager setLocationTimeout:6];
        [_locationManager setReGeocodeTimeout:3];
    }
    return _locationManager;
}

- (AMapSearchAPI *)mapSearch
{
    if (!_mapSearch) {
        _mapSearch = [[AMapSearchAPI alloc] init];
        _mapSearch.delegate = self;
    }
    return _mapSearch;
}

- (AMapPOIAroundSearchRequest *)request
{
    if (!_request) {
        _request = [[AMapPOIAroundSearchRequest alloc] init];
        _request.types  = @"商务住宅|餐饮服务|生活服务|写字楼|学校|医院";
        _request.sortrule = 0; // 按照距离排序.
        _request.offset = 50;
        _request.requireExtension = YES;
    }
    return _request;
}

- (UISearchController *)searchController
{
    if (!_searchController) {
        _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        _searchController.delegate = self;
        _searchController.searchResultsUpdater = self;
        _searchController.dimsBackgroundDuringPresentation = NO;
        
        UISearchBar *bar = _searchController.searchBar;
        bar.barStyle = UIBarStyleDefault;
        bar.translucent = YES;
        bar.barTintColor = [UIColor groupTableViewBackgroundColor];
        bar.tintColor = AppTintColor;
        UIImageView *view = [[[bar.subviews objectAtIndex:0] subviews] firstObject];
        view.layer.borderColor =FX_HEX_COLOR(0xdddddd, 1).CGColor;
        view.layer.borderWidth = 0.7;
        
        bar.showsBookmarkButton = NO;
        UITextField *searchField = [bar valueForKey:@"searchField"];
        searchField.placeholder = @"搜索地点";
        if (searchField) {
            [searchField setBackgroundColor:[UIColor whiteColor]];
            searchField.layer.cornerRadius = 3.0f;
            searchField.layer.borderColor = FX_HEX_COLOR(0xdddddd, 1).CGColor;
            searchField.layer.borderWidth = 0.7;
        }
    }
    return _searchController;
}

- (MAMapView *)mapView
{
    if (!_mapView) {
        _mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
        _mapView.delegate = self;
        _mapView.mapType = MAMapTypeStandard;
        _mapView.showsScale = YES;
        _mapView.showsCompass = YES;
        _mapView.showsUserLocation = YES;
        _mapView.userTrackingMode = MAUserTrackingModeFollow;
    }
    return _mapView;
}

- (UIButton *)locationBtn
{
    if (!_locationBtn) {
        _locationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _locationBtn.frame = CGRectMake(KWIDTH - 60, 240, 50, 50);
        [_locationBtn addTarget:self action:@selector(localButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _locationBtn.layer.cornerRadius = 25;
        _locationBtn.clipsToBounds = YES;
        [_locationBtn setImage:[UIImage imageNamed:@"message_location"] forState:UIControlStateNormal];
    }
    return _locationBtn;
}

- (UITableView *)tableView
{
    if (_tableView == nil)
    {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 408, KWIDTH, KHEIGHT - 408) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
        @WXWeakify(self);
        _tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
            @WXStrongify(self);
            self.currentPage ++ ;
            self.request.page = self.currentPage;
            self.request.location = [AMapGeoPoint locationWithLatitude:self.currentLocationCoordinate.latitude longitude:self.currentLocationCoordinate.longitude];
            [self.mapSearch AMapPOIAroundSearch:self.request];
        }];
        
        [_tableView registerNib:[UINib nibWithNibName:@"POITableViewCell" bundle:nil] forCellReuseIdentifier:POITableViewCellID];
    }
    return _tableView;
}

- (UITableView *)searchTableView
{
    if (_searchTableView == nil) {
        _searchTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, KWIDTH, KHEIGHT - 64) style:UITableViewStylePlain];
        _searchTableView.delegate = self;
        _searchTableView.dataSource = self;
        _searchTableView.tableFooterView = [UIView new];
        
        [_searchTableView registerNib:[UINib nibWithNibName:@"POITableViewCell" bundle:nil] forCellReuseIdentifier:POITableViewCellID];
    }
    return _searchTableView;
}

- (UIView *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor whiteColor];
    }
    return _bottomView;
}

- (UILabel *)addressLabel
{
    if (!_addressLabel) {
        _addressLabel = [[UILabel alloc] init];
        _addressLabel.font = [UIFont systemFontOfSize:16];
        _addressLabel.textColor = [UIColor blackColor];
        _addressLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _addressLabel;
}

- (UIButton *)navigationBtn
{
    if (!_navigationBtn) {
        _navigationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_navigationBtn setImage:[UIImage imageNamed:@"location_navigation"] forState:UIControlStateNormal];
        [_navigationBtn addTarget:self action:@selector(showNavifationSelect) forControlEvents:UIControlEventTouchUpInside];
    }
    return _navigationBtn;
}

- (void)showNavifationSelect
{
    NSArray <NSString *> * titles = @[NSLocalizedString(@"location.navigation.aMap", nil),
                                      NSLocalizedString(@"location.navigation.baidu", nil),
                                      NSLocalizedString(@"location.navigation.apple", nil),
                                      NSLocalizedString(@"location.navigation.google", nil),];
    [self showSheetWithTitle:nil message:NSLocalizedString(@"location.navigation.message", nil) actions:titles complection:^(int index, NSString * _Nullable title) {
        
        switch (index) {
            case 0:
                [self navigationWithAMap];
                break;
            case 1:
                [self navigationWithBaiduMap];
                break;
            case 2:
                [self navigationWithAppleMap];
                break;
            case 3:
                [self navigationWithGoogleMap];
                break;
            default:
                break;
        }
    } cancelComplection:nil];
}

#pragma mark ====================== CLLocationManagerDelegate =======================

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (kCLAuthorizationStatusAuthorizedWhenInUse == status ||
        kCLAuthorizationStatusAuthorizedAlways == status)
    {
        if (WXLocationTypeSend == self.locationType) {
            // 定位
            [self locateAction];
        }
        else {
            [self showMapPoint];
            [self setCenterPoint];
            [self locateAction];
        }
    }
    else {
        NSLog(@"取消定位授权");
    }
}

#pragma mark ====================== 定位 =======================

- (void)locateAction
{
    [SVProgressHUD showWithStatus:@"正在定位..."];
    //带逆地理的单次定位
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        [SVProgressHUD dismiss];
        
        if (error) {
            [SVProgressHUD showInfoWithStatus:@"定位错误"];
            [SVProgressHUD dismissWithDelay:1.3f];
            WXLog(@"locError:{%ld - %@};",(long)error.code,error.localizedDescription);
            if (error.code == AMapLocationErrorLocateFailed) {
                return ;
            }
        }
        //定位信息
        WXLog(@"location:%@", location);
        if (regeocode)
        {
            if (WXLocationTypeSend == self.locationType) {
                self.currentLocationCoordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
                self.addressString = regeocode.formattedAddress;
                self.city = regeocode.city;
                [self showMapPoint];
                [self setCenterPoint];
                self.request.location = [AMapGeoPoint locationWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
                [self.mapSearch AMapPOIAroundSearch:self.request];
            } else {
                self.startLocation = location.coordinate;
            }
        }
    }];
}

- (void)showMapPoint {
    [_mapView setZoomLevel:15.1 animated:YES];
    if (WXLocationTypeSend == self.locationType) {
        [_mapView setCenterCoordinate:self.currentLocationCoordinate animated:YES];
    } else {
        [_mapView setCenterCoordinate:self.location animated:YES];
    }
}

- (void)setCenterPoint {
    MAPointAnnotation * centerAnnotation = [[MAPointAnnotation alloc] init];//初始化注解对象
    if (WXLocationTypeSend == self.locationType) {
        centerAnnotation.coordinate = self.currentLocationCoordinate;//定位经纬度
    } else {
        centerAnnotation.coordinate = self.location;//定位经纬度
        centerAnnotation.lockedToScreen = YES;
    }
    centerAnnotation.title = @"";
    centerAnnotation.subtitle = @"";
    [self.mapView addAnnotation:centerAnnotation];//添加注解
}

#pragma mark - MAMapView Delegate
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        MAPinAnnotationView *annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:PointReuseIndentifier];
        annotationView.canShowCallout= YES;       //设置气泡可以弹出，默认为NO
        annotationView.animatesDrop = YES;        //设置标注动画显示，默认为NO
        if (WXLocationTypeSend == self.locationType) {
            annotationView.draggable = YES;        //设置标注可以拖动，默认为NO
        } else {
            annotationView.draggable = NO;        //设置标注可以拖动，默认为NO
        }
        annotationView.pinColor = MAPinAnnotationColorRed;
        return annotationView;
    }
    return nil;
}

- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    CLLocationCoordinate2D centerCoordinate = mapView.region.center;
    self.currentLocationCoordinate = centerCoordinate;
    
    MAPointAnnotation * centerAnnotation = [[MAPointAnnotation alloc] init];
    centerAnnotation.coordinate = centerCoordinate;
    centerAnnotation.title = @"";
    centerAnnotation.subtitle = @"";
    [self.mapView addAnnotation:centerAnnotation];
    //主动选择地图上的地点
    if (!self.isSelectedAddress) {
        [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
        self.selectedIndexPath=[NSIndexPath indexPathForRow:0 inSection:0];
        self.request.location = [AMapGeoPoint locationWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];
        self.currentPage = 1;
        self.request.page = self.currentPage;
        [self.mapSearch AMapPOIAroundSearch:self.request];
    }
    self.isSelectedAddress = NO;
    
}

#pragma mark -AMapSearchDelegate
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response{
    NSMutableArray *remoteArray = response.pois.mutableCopy;
    if (self.currentPOI) {
        [remoteArray insertObject:self.currentPOI atIndex:0];
    }
    if (self.currentPage == 1) {
        self.dataArray = remoteArray.copy;
    }else{
        NSMutableArray * moreArray = self.dataArray.mutableCopy;
        [moreArray addObjectsFromArray:remoteArray];
        self.dataArray = moreArray.copy;
    }
    
    if (response.pois.count< 50) {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
    }else{
        [self.tableView.mj_footer endRefreshing];
    }
    [self.tableView reloadData];
    
    
}

- (void)onInputTipsSearchDone:(AMapInputTipsSearchRequest *)request response:(AMapInputTipsSearchResponse *)response{
    
    self.tipsArray = response.tips;
    [self.searchTableView reloadData];
    
}

#pragma mark - UITableViewDelegate && UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == self.tableView) {
        return self.dataArray.count;
    }else{
        return self.tipsArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    POITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:POITableViewCellID forIndexPath:indexPath];
    if (tableView == self.tableView) {
        AMapPOI *POIModel = self.dataArray[indexPath.row];
        cell.nameLabel.text = POIModel.name;
        cell.addressLable.text = [NSString stringWithFormat:@"%@%@%@%@",POIModel.province,POIModel.city,POIModel.district,POIModel.address];
        if (indexPath.row==self.selectedIndexPath.row){
            cell.accessoryType=UITableViewCellAccessoryCheckmark;
        }else{
            cell.accessoryType=UITableViewCellAccessoryNone;
        }
    }
    else {
        AMapTip *tipModel = self.tipsArray[indexPath.row];
        cell.nameLabel.text = tipModel.name;
        cell.addressLable.text = [NSString stringWithFormat:@"%@%@",tipModel.district,tipModel.address];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == tableView) {
        self.selectedIndexPath=indexPath;
        [tableView reloadData];
        AMapPOI *POIModel = self.dataArray[indexPath.row];
        CLLocationCoordinate2D locationCoordinate = CLLocationCoordinate2DMake(POIModel.location.latitude, POIModel.location.longitude);
        [_mapView setCenterCoordinate:locationCoordinate animated:YES];
        self.isSelectedAddress = YES;
    }
    else{
        self.searchController.active = NO;
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        AMapTip *tipModel = self.tipsArray[indexPath.row];
        CLLocationCoordinate2D locationCoordinate = CLLocationCoordinate2DMake(tipModel.location.latitude, tipModel.location.longitude);
        [_mapView setCenterCoordinate:locationCoordinate animated:YES];
        self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];

        AMapPOI *POIModel = [AMapPOI new];
        POIModel.address = [NSString stringWithFormat:@"%@%@",tipModel.district,tipModel.address];
        POIModel.location = tipModel.location;
        POIModel.name = tipModel.name;
        self.currentPOI = POIModel;
        [self.tableView reloadData];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView == self.searchTableView) {
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    }
}

#pragma mark - UISearchControllerDelegate && UISearchResultsUpdating

//谓词搜索过滤
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    if (searchController.searchBar.text.length == 0) {
        return;
    }
    [self.view addSubview:self.searchTableView];
    AMapInputTipsSearchRequest *tips = [[AMapInputTipsSearchRequest alloc] init];
    tips.keywords = searchController.searchBar.text;
    tips.city = self.city;
    [self.mapSearch AMapInputTipsSearch:tips];
    
}

#pragma mark - UISearchControllerDelegate代理
- (void)willPresentSearchController:(UISearchController *)searchController{
    self.searchController.searchBar.frame = CGRectMake(0, 0, self.searchController.searchBar.frame.size.width, 44.0);
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    self.mapView.frame = CGRectMake(0, 64, KWIDTH, 300);
    
}
- (void)willDismissSearchController:(UISearchController *)searchController{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent ];
}


- (void)didDismissSearchController:(UISearchController *)searchController{
    self.searchController.searchBar.frame = CGRectMake(0, 64, self.searchController.searchBar.frame.size.width, 44.0);
    self.mapView.frame = CGRectMake(0, 64 + 44, KWIDTH, 300);
    
    [self.searchTableView removeFromSuperview];
}

#pragma mark - buttonAction
- (void)sendLocation
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(sendLocationLatitude:longitude:andAddress:andAddressSnapshotImage:imageSize:andName:)]) {
        
        AMapPOI *POIModel = self.dataArray[self.selectedIndexPath.row];
        __block NSString *address = [NSString stringWithFormat:@"%@%@%@", POIModel.city, POIModel.district, POIModel.address];
        __block CGRect snapshotRect = CGRectMake(0, 0, KWIDTH, KWIDTH *2 /3.0);
        [self.mapView takeSnapshotInRect:snapshotRect withCompletionBlock:^(UIImage *resultImage, CGRect rect) {
            [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                __block NSData *resultData = UIImagePNGRepresentation(resultImage);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.delegate sendLocationLatitude:POIModel.location.latitude longitude:POIModel.location.longitude andAddress:address andAddressSnapshotImage:resultData imageSize:snapshotRect.size andName:POIModel.name];
                }];
            }];
        }];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)localButtonAction{
    [self locateAction];
}


// 高德导航
- (void)navigationWithAMap
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        NSString *urlsting =[[NSString stringWithFormat:@"iosamap://path?sourceApplication=%@&sid=BGVIS1&slat=%f&slon=%f&sname=%@&did=BGVIS2&dlat=%f&dlon=%f&dname=%@&dev=0&m=0&t=0", @"weixun", self.startLocation.latitude, self.startLocation.longitude, @"我的位置", self.location.latitude, self.location.longitude, self.address] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlsting]];
    }
    else {
        [self showAlertWithTitle:nil message:@"你的手机未安装高德地图,是否现在安装?" sureTitle:@"确定" cancelTitle:@"取消" sureComplection:^{
            NSString *aMapUrl = @"https://itunes.apple.com/cn/app/%E9%AB%98%E5%BE%B7%E5%9C%B0%E5%9B%BE-%E7%B2%BE%E5%87%86%E5%9C%B0%E5%9B%BE-%E5%AF%BC%E8%88%AA%E5%87%BA%E8%A1%8C%E5%BF%85%E5%A4%87/id461703208?mt=8";
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:aMapUrl]]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:aMapUrl]];
            } else {
                [SVProgressHUD showInfoWithStatus:@"安装高德地图失败"];
                [SVProgressHUD dismissWithDelay:0.8];
            }
        } cancelComplection:nil];
    }
}

// 百度导航
- (void)navigationWithBaiduMap
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        NSString *urlsting =[[NSString stringWithFormat:@"baidumap://map/direction?origin={{%@}}&destination=latlng:%f,%f|name=%@&mode=driving&coord_type=gcj02", @"我的位置", self.location.latitude, self.location.longitude, self.address] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlsting]];
    }
    else {
        [self showAlertWithTitle:nil message:@"你的手机未安装百度地图,是否现在安装?" sureTitle:@"确定" cancelTitle:@"取消" sureComplection:^{
            NSString *baiduUrl = @"https://itunes.apple.com/cn/app/%E7%99%BE%E5%BA%A6%E5%9C%B0%E5%9B%BE-%E8%B7%AF%E7%BA%BF%E8%A7%84%E5%88%92-%E5%87%BA%E8%A1%8C%E5%BF%85%E5%A4%87/id452186370?mt=8";
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:baiduUrl]]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:baiduUrl]];
            } else {
                [SVProgressHUD showInfoWithStatus:@"安装百度地图失败"];
                [SVProgressHUD dismissWithDelay:0.8];
            }
        } cancelComplection:nil];
    }
}

// Apple导航
- (void)navigationWithAppleMap
{
    MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
    MKMapItem *tolocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:self.location addressDictionary:nil]];
    tolocation.name = self.address;
    [MKMapItem openMapsWithItems:@[currentLocation,tolocation] launchOptions:@{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsShowsTrafficKey:[NSNumber numberWithBool:YES]}];
}

// Google导航
- (void)navigationWithGoogleMap
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
         NSString *urlString = [[NSString stringWithFormat:@"comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%f,%f&directionsmode=driving",
          @"weixun", @"weixun", self.location.latitude, self.location.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    }
    else {
        [self showAlertWithTitle:nil message:@"你的手机未安装Google地图,是否现在安装?" sureTitle:@"确定" cancelTitle:@"取消" sureComplection:^{
            NSString *googleUrl = @"https://itunes.apple.com/cn/app/google-%E5%9C%B0%E5%9B%BE/id585027354?mt=8";
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:googleUrl]]) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:googleUrl]];
            } else {
                [SVProgressHUD showInfoWithStatus:@"安装Google地图失败"];
                [SVProgressHUD dismissWithDelay:0.8];
            }
        } cancelComplection:nil];
    }
}

@end
