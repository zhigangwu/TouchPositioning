//
//  TouchPositioning_ViewController.m
//  TouchPositioning
//
//  Created by 吴志刚 on 2019/3/13.
//  Copyright © 2019 HJ. All rights reserved.
//

#import "TouchPositioning_ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

static int WIDTH = 365;
static int HEIGHT = 667;

@interface TouchPositioning_ViewController () <MKMapViewDelegate,CLLocationManagerDelegate,UITextFieldDelegate,UIGestureRecognizerDelegate>
{
    NSString *detileAddressStr;
    CGFloat longitudeFloat;
    CGFloat latitudeFloat;
    
    NSString *state;
    NSString *city;
    NSString *subLocality;
    NSString *street;
}

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) UITextField *addressTextField;


@end

@implementation TouchPositioning_ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    [self initMapView];
    [self initLocationManager];
    [self initAddressTextField];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]; // 长按手势
    longPress.delegate = self;
    [_mapView addGestureRecognizer:longPress];
}

- (void)initMapView {
    _mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, WIDTH,HEIGHT)];
    _mapView.delegate = self;
    _mapView.mapType = MKMapTypeStandard;
    [self.view addSubview:_mapView];
}

- (void)initLocationManager {
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest; // 定位精度
    _locationManager.delegate = self;
    _locationManager.distanceFilter = 100;
    [_locationManager requestWhenInUseAuthorization];
}

- (void)initAddressTextField {
    _addressTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 40, UIScreen.mainScreen.bounds.size.width - 40, 40)];
    _addressTextField.delegate = self;
    _addressTextField.returnKeyType = UIReturnKeyDone;
    _addressTextField.backgroundColor = UIColor.whiteColor;
    _addressTextField.layer.cornerRadius = 8;
    _addressTextField.layer.masksToBounds = YES;
    _addressTextField.layer.borderWidth = 0.5;
    _addressTextField.layer.borderColor = UIColor.grayColor.CGColor;
    _addressTextField.placeholder = @"请输入详细地址";
    [_mapView addSubview:_addressTextField];
    [_addressTextField addTarget:self action:@selector(contentWillChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)contentWillChange:(UITextField *)textFiled {
    detileAddressStr = textFiled.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_locationManager startUpdatingLocation];
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (_mapView.annotations.count > 0) {
        NSMutableArray *removeAnnotations = [[NSMutableArray alloc]init];
        //将所有需要移除打大头针添加一个数组，去掉当前位置的大头针
        [removeAnnotations addObjectsFromArray:self.mapView.annotations];
        [removeAnnotations removeObject:self.mapView.userLocation];
        //移除需要移除的大头针
        [self.mapView removeAnnotations:removeAnnotations];
    }
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:detileAddressStr completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (error || placemarks.count == 0) {
            NSLog(@"你输入的地址找不到，可能在火星上");
        } else {
            for (CLPlacemark *placemark in placemarks) {
                NSLog(@"%@ %@ %@",placemark.country,placemark.locality,placemark.name);
            }
            
            CLPlacemark *firstPlacemark = [placemarks firstObject];
            NSLog(@"longitude = %.2f",firstPlacemark.location.coordinate.longitude);
            NSLog(@"longitude = %.2f",firstPlacemark.location.coordinate.latitude);
            NSLog(@"%@ %@ %@",firstPlacemark.country,firstPlacemark.locality,firstPlacemark.name);
            
            self->longitudeFloat = firstPlacemark.location.coordinate.longitude;
            self->latitudeFloat = firstPlacemark.location.coordinate.latitude;
            
            [self setLocationWithLatitude:firstPlacemark.location.coordinate.latitude AndLongitude:firstPlacemark.location.coordinate.longitude];
        }
    }];
}

- (void)setLocationWithLatitude:(CLLocationDegrees)latitude AndLongitude:(CLLocationDegrees)longitude{
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = location.coordinate;
    point.title = @"当前位置";
    [self->_mapView addAnnotation:point];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500);
    [self->_mapView setRegion:region animated:YES];
    
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"反编码失败:%@",error);
        }else{
            CLPlacemark *placemark = [placemarks lastObject];
            NSDictionary *addressDic = placemark.addressDictionary;
            
            self->state = [addressDic objectForKey:@"State"];
            self->city = [addressDic objectForKey:@"City"];
            self->subLocality = [addressDic objectForKey:@"SubLocality"];
            self->street = [addressDic objectForKey:@"Street"];
            
            NSLog(@"%@%@%@%@",self->state,self->city,self->subLocality,self->street);
            NSString *strLocation;
            if (self->street.length == 0 || self->street == NULL || [self->street isEqualToString:@"(null)"]) {
                strLocation = [NSString stringWithFormat:@"%@%@%@",self->state,self->city,self->subLocality];
            }else{
                strLocation = [NSString stringWithFormat:@"%@%@%@%@",self->state,self->city,self->subLocality,self->street];
            }
            
            CLLocation *location = [[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
            
            MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
            point.coordinate = location.coordinate;
            
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500);
            [self->_mapView setRegion:region animated:YES];
        }
    }];
    [_locationManager stopUpdatingLocation];
}

- (void)longPress:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        return;
    }
    
    if (_mapView.annotations.count > 0) {
        NSMutableArray *removeAnnotations = [[NSMutableArray alloc]init];
        //将所有需要移除打大头针添加一个数组，去掉当前位置的大头针
        [removeAnnotations addObjectsFromArray:self.mapView.annotations];
        [removeAnnotations removeObject:self.mapView.userLocation];
        //移除需要移除的大头针
        [self.mapView removeAnnotations:removeAnnotations];
    }
    
    //坐标转换
    CGPoint touchPoint = [gestureRecognizer locationInView:_mapView];
    CLLocationCoordinate2D touchMapCoordinate = [_mapView convertPoint:touchPoint toCoordinateFromView:_mapView];
    
    [self setLocationWithLatitude:touchMapCoordinate.latitude AndLongitude:touchMapCoordinate.longitude];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
