//
//  XOLocationViewController.m
//  XOChatModule_Example
//
//  Created by kenter on 2019/10/9.
//  Copyright © 2019 kenter. All rights reserved.
//

#import "XOLocationViewController.h"
#import "NSBundle+ChatModule.h"
#import "UIImage+XOChatBundle.h"

#import <MapKit/MapKit.h>
#import <SVProgressHUD/SVProgressHUD.h>

#define MapHeight KHEIGHT * (400.0/667.0)
static NSString * const POITableViewCellID = @"POITableViewCellID";
static NSString * const PointReuseIndentifier = @"pointReuseIndentifier";

@interface XOLocationViewController () <UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, MKMapViewDelegate>

@property (nonatomic, strong) UITableView        *tableView;
@property (nonatomic ,strong) UITableView        *searchTableView; //用于搜索的tableView
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) MKMapView          *mapView;
@property (nonatomic, strong) UIButton           *locationBtn;

@property (nonatomic, strong) UIView             *bottomView;
@property (nonatomic, strong) UILabel            *addressLabel;
@property (nonatomic, strong) UIButton           *navigationBtn;

@property (nonatomic, assign) NSInteger          currentPage;
@property (nonatomic, assign) BOOL               isSelectedAddress;
@property (nonatomic, strong) NSIndexPath        *selectedIndexPath;

@property (nonatomic, strong) NSString           *addressString;
@property (nonatomic, strong) NSString           *city;//定位的当前城市，用于搜索功能

@property (nonatomic, strong) NSArray            *dataArray;
@property (nonatomic, strong) NSArray            *tipsArray;//搜索提示的数组

//@property (nonatomic, strong) AMapPOIAroundSearchRequest *request;
@property (nonatomic, strong) CLLocationManager        *locationManager;
//@property (nonatomic, strong) AMapSearchAPI              *mapSearch;
//@property (nonatomic, strong) AMapPOI                    *currentPOI;//点击选择的当前的位置插入到数组中
@property (nonatomic, assign) CLLocationCoordinate2D     currentLocationCoordinate;
@property (nonatomic, assign) CLLocationCoordinate2D     startLocation;

@end

@implementation XOLocationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = XOChatLocalizedString(@"chat.location.title");
    
    [self initilization];
    
    [self setupSubViews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (XOLocationTypeSend == self.locationType) {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if (kCLAuthorizationStatusNotDetermined == status) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        else if (kCLAuthorizationStatusDenied == status || kCLAuthorizationStatusRestricted == status) {
            [self showAlertAuthor:XORequestAuthLocation];
        } else {
            [SVProgressHUD showWithStatus:@"正在定位..."];
            [self.locationManager startUpdatingLocation];
        }
    } else {
        [self showMapPoint];
        [self setCenterPoint];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (XOLocationTypeSend == self.locationType) {
        self.searchController.searchBar.frame = CGRectMake(0, 0, KWIDTH, 44);
        self.mapView.frame = CGRectMake(0, 44, KWIDTH, MapHeight);
        self.tableView.frame = CGRectMake(0, (MapHeight + 44), KWIDTH, self.view.height - MapHeight - 44);
        self.locationBtn.frame = CGRectMake(KWIDTH - 60, MapHeight - 70, 50, 50);
    } else {
        self.mapView.frame = CGRectMake(0, 0, KWIDTH, self.view.height - 64);
        self.bottomView.frame = CGRectMake(0, self.view.height - 64, KWIDTH, 64);
        self.navigationBtn.frame = CGRectMake(KWIDTH - 20 - 50, 7, 50, 50);
        self.addressLabel.frame = CGRectMake(20, 17, KWIDTH - 110, 30);
    }
}

- (void)initilization
{
    if (XOLocationTypeSend == self.locationType) {
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
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    if (@available(iOS 11.0, *)) {
        [UIScrollView appearance].contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [self.view addSubview:self.mapView];
    
    if (XOLocationTypeSend == self.locationType) {
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
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    [cancelButton setTitle:XOChatLocalizedString(@"chat.cancel") forState:UIControlStateNormal];
    [cancelButton setTitleColor:AppTinColor forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [cancelButton addTarget:self action:@selector(cancelPick) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    
    UIBarButtonItem *nagativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    nagativeSpacer.width = 10;
    [self.navigationItem setLeftBarButtonItems:@[nagativeSpacer,cancelItem]];
    
    UIButton *sendButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    [sendButton setTitle:XOChatLocalizedString(@"chat.location.send") forState:UIControlStateNormal];
    [sendButton setTitleColor:AppTinColor forState:UIControlStateNormal];
    sendButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [sendButton addTarget:self action:@selector(sendLocation) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    UIBarButtonItem *sendItem = [[UIBarButtonItem alloc] initWithCustomView:sendButton];
    
    UIBarButtonItem *nagativeSpacer1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    nagativeSpacer1.width = -10;
    [self.navigationItem setRightBarButtonItems:@[nagativeSpacer1,sendItem]];
}

#pragma mark ====================== lazy =======================

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
        [_locationManager setDistanceFilter:kCLDistanceFilterNone];
    }
    return _locationManager;
}
/*
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
*/
- (UISearchController *)searchController
{
    if (!_searchController) {
        _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        _searchController.delegate = self;
        _searchController.searchResultsUpdater = self;
        _searchController.dimsBackgroundDuringPresentation = NO;
        _searchController.hidesNavigationBarDuringPresentation = NO;
        _searchController.view.backgroundColor = [UIColor clearColor];
        if (@available(iOS 9.1, *)) {
            _searchController.obscuresBackgroundDuringPresentation = NO;
        }
        
        UISearchBar *bar = _searchController.searchBar;
        bar.barStyle = UIBarStyleDefault;
        bar.translucent = YES;
        bar.barTintColor = [UIColor groupTableViewBackgroundColor];
        bar.tintColor = AppTinColor;
        UIImageView *view = [[[bar.subviews objectAtIndex:0] subviews] firstObject];
        view.layer.borderColor = RGBOF(0xdddddd).CGColor;
        view.layer.borderWidth = 0.7;
        
        bar.showsBookmarkButton = NO;
        UITextField *searchField = [bar valueForKey:@"searchField"];
        searchField.placeholder = XOChatLocalizedString(@"chat.location.searchAddress");
        if (searchField) {
            [searchField setBackgroundColor:[UIColor whiteColor]];
            searchField.layer.cornerRadius = 3.0f;
            searchField.layer.borderColor = RGBOF(0xdddddd).CGColor;
            searchField.layer.borderWidth = 0.7;
        }
    }
    return _searchController;
}

- (MKMapView *)mapView
{
    if (!_mapView) {
        _mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
        _mapView.delegate = self;
        _mapView.mapType = MKMapTypeStandard;
        _mapView.showsScale = YES;
        _mapView.zoomEnabled = YES;
        _mapView.showsCompass = YES;
        _mapView.showsUserLocation = YES;
        _mapView.userTrackingMode = MKUserTrackingModeFollow;
        MKCoordinateSpan span = MKCoordinateSpanMake(0.021251, 0.016093);
        [_mapView setRegion:MKCoordinateRegionMake(_mapView.userLocation.coordinate, span) animated:YES];
    }
    return _mapView;
}

- (UIButton *)locationBtn
{
    if (!_locationBtn) {
        _locationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_locationBtn addTarget:self action:@selector(localButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _locationBtn.layer.cornerRadius = 25;
        _locationBtn.clipsToBounds = YES;
        [_locationBtn setImage:[UIImage xo_imageNamedFromChatBundle:@"message_location"] forState:UIControlStateNormal];
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
        [_tableView registerClass:[POITableViewCell class] forCellReuseIdentifier:POITableViewCellID];
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
        
        [_tableView registerClass:[POITableViewCell class] forCellReuseIdentifier:POITableViewCellID];
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
        [_navigationBtn setImage:[UIImage xo_imageNamedFromChatBundle:@"location_navigation"] forState:UIControlStateNormal];
        [_navigationBtn addTarget:self action:@selector(showNavifationSelect) forControlEvents:UIControlEventTouchUpInside];
    }
    return _navigationBtn;
}

- (void)showNavifationSelect
{
    NSArray <NSString *> * titles = @[XOChatLocalizedString(@"chat.location.navigation.aMap"),
                                      XOChatLocalizedString(@"chat.location.navigation.baidu"),
                                      XOChatLocalizedString(@"chat.location.navigation.apple"),
                                      XOChatLocalizedString(@"chat.location.navigation.google")];
    [self showSheetWithTitle:nil message:XOChatLocalizedString(@"chat.location.navigation.message") actions:titles redIndex:nil complection:^(int index, NSString * _Nullable title) {
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
    if (kCLAuthorizationStatusAuthorizedWhenInUse == status || kCLAuthorizationStatusAuthorizedAlways == status)
    {
        if (XOLocationTypeRecive == self.locationType) {
            [self showMapPoint];
            [self setCenterPoint];
        }
        [SVProgressHUD showWithStatus:@"正在定位..."];
        [self.locationManager startUpdatingLocation];
    }
    else if (kCLAuthorizationStatusDenied == status || kCLAuthorizationStatusRestricted == status) {
        [self showAlertAuthor:XORequestAuthLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    [SVProgressHUD dismiss];
    if (locations && locations.count > 0) {
        // 停止刷新
        [manager stopUpdatingLocation];
        
        CLLocation *location = locations[0];
        if (XOLocationTypeSend == self.locationType) {
            self.currentLocationCoordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
            
            // 保存 Device 的现语言
            NSMutableArray *deviceLanguages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
            // 强制转换成 App 当前语言
            XOLanguageName language = [XOSettingManager defaultManager].language;
            [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:language,nil] forKey:@"AppleLanguages"];
            
            CLGeocoder *geocoder = [[CLGeocoder alloc] init];
            [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
               if (!error) {
                   for (CLPlacemark *place in placemarks) {
                        self.city = place.locality;
                        NSString *administrativeArea = place.administrativeArea;
                        if ([self.city isEqualToString:administrativeArea]) {
                            // 四大直辖市
                            self.addressString = [NSString stringWithFormat:@"%@%@", self.city, place.subLocality];
                        } else {
                            self.addressString = [NSString stringWithFormat:@"%@%@", administrativeArea, self.city];
                        }
                        break;
                    }
                }
                // 还原 Device 的现语言
                [[NSUserDefaults standardUserDefaults] setObject:deviceLanguages forKey:@"AppleLanguages"];
                
                // 添加搜索数据结果
                if (self.currentPage == 1) {
                    self.dataArray = [placemarks copy];
                } else {
                    NSMutableArray * moreArray = self.dataArray.mutableCopy;
                    [moreArray addObjectsFromArray:placemarks];
                    self.dataArray = moreArray;
                }
                [self.tableView reloadData];
            }];
            
            [self showMapPoint];
            [self setCenterPoint];
//            self.request.location = [AMapGeoPoint locationWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
//            [self.mapSearch AMapPOIAroundSearch:self.request];
        } else {
            self.startLocation = location.coordinate;
        }
    }
}

#pragma mark ====================== 定位 =======================

- (void)showMapPoint {
    if (XOLocationTypeSend == self.locationType) {
        [_mapView setCenterCoordinate:self.currentLocationCoordinate animated:YES];
    } else {
        [_mapView setCenterCoordinate:self.location animated:YES];
    }
}

- (void)setCenterPoint {
    MKPointAnnotation * centerAnnotation = [[MKPointAnnotation alloc] init];//初始化注解对象
    if (XOLocationTypeSend == self.locationType) {
        centerAnnotation.coordinate = self.currentLocationCoordinate;//定位经纬度
    } else {
        centerAnnotation.coordinate = self.location;//定位经纬度
    }
    centerAnnotation.title = @"";
    centerAnnotation.subtitle = @"";
    [self.mapView addAnnotation:centerAnnotation];//添加注解
}

#pragma mark ========================= MKMapViewDelegate =========================

- (nullable MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;
{
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:PointReuseIndentifier];
        annotationView.canShowCallout= YES;       //设置气泡可以弹出，默认为NO
        annotationView.animatesDrop = YES;        //设置标注动画显示，默认为NO
        if (XOLocationTypeSend == self.locationType) {
            annotationView.draggable = YES;        //设置标注可以拖动，默认为NO
        } else {
            annotationView.draggable = NO;        //设置标注可以拖动，默认为NO
        }
        annotationView.pinTintColor = AppTinColor;
        return annotationView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated;
{
    if (XOLocationTypeSend == self.locationType) {
        [self.mapView removeAnnotations:self.mapView.annotations];
        
        CLLocationCoordinate2D centerCoordinate = mapView.region.center;
        self.currentLocationCoordinate = centerCoordinate;
        
        MKPointAnnotation * centerAnnotation = [[MKPointAnnotation alloc] init];
        centerAnnotation.coordinate = centerCoordinate;
        centerAnnotation.title = @"";
        centerAnnotation.subtitle = @"";
        [self.mapView addAnnotation:centerAnnotation];
        //主动选择地图上的地点
        if (!self.isSelectedAddress) {
            [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
            self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            //        self.request.location = [AMapGeoPoint locationWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];
            //        self.request.page = self.currentPage;
            //        [self.mapSearch AMapPOIAroundSearch:self.request];
        }
        self.isSelectedAddress = NO;
    }
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
        CLPlacemark *placemark = self.dataArray[indexPath.row];
        cell.POIName = placemark.name;
        cell.addressName = [NSString stringWithFormat:@"%@%@%@%@%@", placemark.country, placemark.administrativeArea, placemark.locality, placemark.subLocality, placemark.thoroughfare];
        if (indexPath.row==self.selectedIndexPath.row){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else {
//        AMapTip *tipModel = self.tipsArray[indexPath.row];
//        cell.nameLabel.text = tipModel.name;
//        cell.addressLable.text = [NSString stringWithFormat:@"%@%@",tipModel.district,tipModel.address];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == tableView) {
        self.selectedIndexPath = indexPath;
        [tableView reloadData];
        CLPlacemark *placemark = self.dataArray[indexPath.row];
        CLLocationCoordinate2D locationCoordinate = CLLocationCoordinate2DMake(placemark.location.coordinate.latitude, placemark.location.coordinate.longitude);
        [_mapView setCenterCoordinate:locationCoordinate animated:YES];
        self.isSelectedAddress = YES;
    }
    else{
        self.searchController.active = NO;
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
//        AMapTip *tipModel = self.tipsArray[indexPath.row];
//        CLLocationCoordinate2D locationCoordinate = CLLocationCoordinate2DMake(tipModel.location.latitude, tipModel.location.longitude);
//        [_mapView setCenterCoordinate:locationCoordinate animated:YES];
//        self.selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//
//        AMapPOI *POIModel = [AMapPOI new];
//        POIModel.address = [NSString stringWithFormat:@"%@%@",tipModel.district,tipModel.address];
//        POIModel.location = tipModel.location;
//        POIModel.name = tipModel.name;
//        self.currentPOI = POIModel;
//        [self.tableView reloadData];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView == self.searchTableView) {
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    }
}

#pragma mark - UISearchControllerDelegate && UISearchResultsUpdating

// 谓词搜索过滤
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    if (searchController.searchBar.text.length == 0) {
        return;
    }
    [self.view addSubview:self.searchTableView];
    
    NSString *address = searchController.searchBar.text;
    if (!XOIsEmptyString(address)) {
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            if ([placemarks count] > 0 && error == nil)
            {
                // 处理第一个地址
                CLPlacemark * placemark = [placemarks objectAtIndex:0];
                // 设置地图显示的范围, 越小细节越清楚
                MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01);
                MKCoordinateRegion region = {placemark.location.coordinate, span};
                // 设置地图中心位置为搜索到的位置
                [self.mapView setRegion:region];
                // 创建一个MKPointAnnotation，该对象将作为地图锚点
                MKPointAnnotation *point = [[MKPointAnnotation alloc]init];
                // 设置地图锚点的坐标
                point.coordinate = placemark.location.coordinate;
                // 设置地图锚点的标题
                point.title = placemark.name;
                // 设置地图锚点的副标题
                point.subtitle = [NSString stringWithFormat:@"%@%@%@%@%@", placemark.country, placemark.administrativeArea, placemark.locality, placemark.subLocality, placemark.thoroughfare];
                // 将地图锚点添加到地图上
                [self.mapView addAnnotation:point];
                // 选中指定锚点
                [self.mapView selectAnnotation:point animated:YES];
            }
            else {
                NSLog(@"没有搜索到匹配数据");
            }
            
            // 添加搜索数据结果
            if (self.currentPage == 1) {
                self.dataArray = [placemarks copy];
            } else {
                NSMutableArray * moreArray = self.dataArray.mutableCopy;
                [moreArray addObjectsFromArray:placemarks];
                self.dataArray = moreArray;
            }
            [self.tableView reloadData];
        }];
    }
}

#pragma mark - UISearchControllerDelegate代理

- (void)didDismissSearchController:(UISearchController *)searchController
{
    [self.searchTableView removeFromSuperview];
}

#pragma mark ========================= touch event =========================

- (void)cancelPick
{
    [self.locationManager stopUpdatingLocation];
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)sendLocation
{
    [self.locationManager stopUpdatingLocation];
    if (self.delegate && [self.delegate respondsToSelector:@selector(locationViewController:pickLocationLatitude:longitude:addressDesc:)]) {
        
        CLPlacemark *placemark = self.dataArray[self.selectedIndexPath.row];
        double latitude = placemark.location.coordinate.latitude;
        double longitude = placemark.location.coordinate.longitude;
        NSString *address = [NSString stringWithFormat:@"%@%@%@%@%@", placemark.country, placemark.administrativeArea, placemark.locality, placemark.subLocality, placemark.thoroughfare];
        [self.delegate locationViewController:self pickLocationLatitude:latitude longitude:longitude addressDesc:address];
    }
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)localButtonAction
{
    [SVProgressHUD showWithStatus:@"正在定位..."];
    [self.locationManager startUpdatingLocation];
}

// 高德导航
- (void)navigationWithAMap
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        NSString *urlsting =[[NSString stringWithFormat:@"iosamap://path?sourceApplication=%@&sid=BGVIS1&slat=%f&slon=%f&sname=%@&did=BGVIS2&dlat=%f&dlon=%f&dname=%@&dev=0&m=0&t=0", @"xochat", self.startLocation.latitude, self.startLocation.longitude, @"我的位置", self.location.latitude, self.location.longitude, self.address] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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




@interface POITableViewCell ()

@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *addressLabel;

@end

@implementation POITableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.addressLabel];
    }
    return self;
}

- (UILabel *)nameLabel
{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = [UIColor darkTextColor];
        _nameLabel.font = [UIFont systemFontOfSize:17.0f];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _nameLabel;
}

- (UILabel *)addressLabel
{
    if (!_addressLabel) {
        _addressLabel = [[UILabel alloc] init];
        _addressLabel.textColor = [UIColor lightGrayColor];
        _addressLabel.font = [UIFont systemFontOfSize:14.0f];
        _addressLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _addressLabel;
}

- (void)setPOIName:(NSString *)POIName
{
    _POIName = [POIName copy];
    self.nameLabel.text = _POIName;
}

- (void)setAddressName:(NSString *)addressName
{
    _addressName = [addressName copy];
    self.addressLabel.text = _addressName;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.nameLabel.frame = CGRectMake(20, 0, self.width - 50, 30);
    self.addressLabel.frame = CGRectMake(20, 30, self.width - 50, 20);
}

@end
