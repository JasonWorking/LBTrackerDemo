//
//  LBLocationTracker.m
//  BgTracker
//
//  Created by Jason on 15/7/27.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import "LBLocationTracker.h"
#import "LBHTTPClient.h"
#import "LBLocationRecord.h"
#import "LBSenserRecord.h"
#import "LBPendingDataManager.h"
//#import "LBDeviceInfoManager.h"
#import <CoreMotion/CoreMotion.h>
#define LATITUDE @"latitude"
#define LONGITUDE @"longitude"
#define ACCURACY @"theAccuracy"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
/**重力*/
#define GravityKey           @"Gravity"

/**加速度*/
#define AccelerometerKey     @"Accelerometer"

/**陀螺仪*/
#define GyroscopeKey         @"Gyroscope"

/**磁场*/
#define MagnetometerKey      @"Magnetometer"

/**最多的次数*/
#define MAX_NUMBER           10

/**间隔秒数*/
#define UPDATE_INTERVAL      3

//
//@interface LBLocationTracker ()
//
//
//@property (nonatomic, strong)   CMMotionManager * motionManager;
//
//@end

@implementation LBLocationTracker{
    CMMotionManager *motionManager;
    NSMutableDictionary *coremotionData;
}

+ (CLLocationManager *)sharedLocationManager {
    static CLLocationManager *_locationManager;
    
    @synchronized(self) {
        if (_locationManager == nil) {
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        }
    }
    return _locationManager;
}

- (id)init {
    if (self==[super init]) {
        //Get the share model and also initialize myLocationArray
        self.scheduler = [LBDataCollectionScheduler sharedInstance];
        self.scheduler.myLocationArray = [[NSMutableArray alloc]init];
        self.dataColletionInterval = 1*60;
        coremotionData = [NSMutableDictionary dictionary];
        [coremotionData setObject:[NSMutableArray array] forKey:GravityKey];
        [coremotionData setObject:[NSMutableArray array] forKey:AccelerometerKey];
        [coremotionData setObject:[NSMutableArray array] forKey:GyroscopeKey];
        [coremotionData setObject:[NSMutableArray array] forKey:MagnetometerKey];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

-(void)applicationEnterBackground{
    CLLocationManager *locationManager = [LBLocationTracker sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    if(IS_OS_8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
    
    //Use the BackgroundTaskManager to manage all the background Task
    self.scheduler.bgTask = [LBBackgroundTaskManager sharedBackgroundTaskManager];
    [self.scheduler.bgTask beginNewBackgroundTask];
}

- (void) restartLocationUpdates
{
    NSLog(@"restartLocationUpdates");
    
    if (self.scheduler.locationTimer) {
        [self.scheduler.locationTimer invalidate];
        self.scheduler.locationTimer = nil;
    }
    
    CLLocationManager *locationManager = [LBLocationTracker sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    if(IS_OS_8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
}



- (void)startLocationTrackingWithTimeInterval:(NSTimeInterval)time
{
    self.dataColletionInterval = MAX(10, time);
    [self startLocationTracking];
}

- (void)startLocationTracking {
    NSLog(@"startLocationTracking");
    
    if ([CLLocationManager locationServicesEnabled] == NO) {
        NSLog(@"locationServicesEnabled false");
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
    } else {
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
            NSLog(@"authorizationStatus failed");
        } else {
            NSLog(@"authorizationStatus authorized");
            CLLocationManager *locationManager = [LBLocationTracker sharedLocationManager];
            locationManager.delegate = self;
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            locationManager.distanceFilter = kCLDistanceFilterNone;
            
            if(IS_OS_8_OR_LATER) {
                [locationManager requestAlwaysAuthorization];
            }
            [locationManager startUpdatingLocation];
        }
    }
}


- (void)stopLocationTracking {
    NSLog(@"stopLocationTracking");
    
    if (self.scheduler.locationTimer) {
        [self.scheduler.locationTimer invalidate];
        self.scheduler.locationTimer = nil;
    }
    
    CLLocationManager *locationManager = [LBLocationTracker sharedLocationManager];
    [locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    
    //    [[LBDeviceInfoManager sharedInstance] startCoreMotionMonitorClearData:YES];
    
    if (!coremotionData) {
        coremotionData = [NSMutableDictionary dictionary];
        [coremotionData setObject:[NSMutableArray array] forKey:GravityKey];
        [coremotionData setObject:[NSMutableArray array] forKey:AccelerometerKey];
        [coremotionData setObject:[NSMutableArray array] forKey:GyroscopeKey];
        [coremotionData setObject:[NSMutableArray array] forKey:MagnetometerKey];
    }
    
    if (motionManager) {
        if (motionManager.accelerometerAvailable) {
            CMDeviceMotion *motion = motionManager.deviceMotion;
            if ([[coremotionData objectForKey:AccelerometerKey] count] < MAX_NUMBER && motion) {
                NSLog(@"acc: %@",@{@"x":[NSNumber numberWithDouble:motion.userAcceleration.x],@"y":[NSNumber numberWithDouble:motion.userAcceleration.y],@"z":[NSNumber numberWithDouble:motion.userAcceleration.z]});
                [[coremotionData objectForKey:AccelerometerKey] addObject:motion];
            }
            
            if ([[coremotionData objectForKey:GravityKey] count] < MAX_NUMBER && motion) {
                NSLog(@"grav: %@",@{@"x":[NSNumber numberWithDouble:motion.gravity.x],@"y":[NSNumber numberWithDouble:motion.gravity.y],@"z":[NSNumber numberWithDouble:motion.gravity.z]});
                [[coremotionData objectForKey:GravityKey] addObject:motion];
            }
        }
        
        if (motionManager.isGyroAvailable) {
            CMGyroData *gyroData = motionManager.gyroData;
            if ([[coremotionData objectForKey:GyroscopeKey] count] < MAX_NUMBER && gyroData) {
                NSLog(@"gyro: %@",@{@"x":[NSNumber numberWithDouble:gyroData.rotationRate.x],@"y":[NSNumber numberWithDouble:gyroData.rotationRate.y],@"z":[NSNumber numberWithDouble:gyroData.rotationRate.z]});
                [[coremotionData objectForKey:GyroscopeKey] addObject:gyroData];
            }
        }
        
        if (motionManager.isMagnetometerAvailable) {
            CMMagnetometerData *magnetometerData = motionManager.magnetometerData;
            if ([[coremotionData objectForKey:MagnetometerKey] count] < MAX_NUMBER && magnetometerData) {
                NSLog(@"magnet: %@",@{@"x":[NSNumber numberWithDouble:magnetometerData.magneticField.x],@"y":[NSNumber numberWithDouble:magnetometerData.magneticField.y],@"z":[NSNumber numberWithDouble:magnetometerData.magneticField.z]});
                [[coremotionData objectForKey:MagnetometerKey] addObject:magnetometerData];
            }
        }
    }
    
    
    NSLog(@"locationManager didUpdateLocations");
    
    for(int i=0;i<locations.count;i++){
        CLLocation * newLocation = [locations objectAtIndex:i];
        CLLocationCoordinate2D theLocation = newLocation.coordinate;
        CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
        
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        
        if (locationAge > 30.0)
        {
            continue;
        }
        
        //Select only valid location and also location with good accuracy
        if(newLocation!=nil&&theAccuracy>0
           &&theAccuracy<2000
           &&(!(theLocation.latitude==0.0&&theLocation.longitude==0.0))){
            
            self.myLastLocation = theLocation;
            self.myLastLocationAccuracy= theAccuracy;
            
            NSMutableDictionary * dict = [[NSMutableDictionary alloc]init];
            [dict setObject:[NSNumber numberWithFloat:theLocation.latitude] forKey:@"latitude"];
            [dict setObject:[NSNumber numberWithFloat:theLocation.longitude] forKey:@"longitude"];
            [dict setObject:[NSNumber numberWithFloat:theAccuracy] forKey:@"theAccuracy"];
            
            //Add the vallid location with good accuracy into an array
            //Every 1 minute, I will select the best location based on accuracy and send to server
            [self.scheduler.myLocationArray addObject:dict];
        }
    }
    
    //If the timer still valid, return it (Will not run the code below)
    if (self.scheduler.locationTimer) {
        return;
    }
    
    self.scheduler.bgTask = [LBBackgroundTaskManager sharedBackgroundTaskManager];
    [self.scheduler.bgTask beginNewBackgroundTask];
    
    //Restart the locationMaanger after X minute
    self.scheduler.locationTimer = [NSTimer scheduledTimerWithTimeInterval:self.dataColletionInterval target:self
                                                                  selector:@selector(restartLocationUpdates)
                                                                  userInfo:nil
                                                                   repeats:NO];
    
    //Will only stop the locationManager after 10 seconds, so that we can get some accurate locations
    //The location manager will only operate for 10 seconds to save battery
    if (self.scheduler.delay10Seconds) {
        [self.scheduler.delay10Seconds invalidate];
        self.scheduler.delay10Seconds = nil;
    }
    
    self.scheduler.delay10Seconds = [NSTimer scheduledTimerWithTimeInterval:10 target:self
                                                                   selector:@selector(stopLocationDelayBy10Seconds)
                                                                   userInfo:nil
                                                                    repeats:NO];
    
    motionManager=[[CMMotionManager alloc] init];
    motionManager.deviceMotionUpdateInterval = 1;
    if (motionManager.deviceMotionAvailable) {
        [motionManager startDeviceMotionUpdates];
    }
    
    if (motionManager.isGyroAvailable) {
        motionManager.gyroUpdateInterval = 1;
        [motionManager startGyroUpdates];
    }
    
    if (motionManager.isMagnetometerAvailable) {
        motionManager.magnetometerUpdateInterval = 1;
        [motionManager startMagnetometerUpdates];
    }
}


//Stop the locationManager
-(void)stopLocationDelayBy10Seconds{
    
    [motionManager stopDeviceMotionUpdates];
    [motionManager  stopMagnetometerUpdates];
    [motionManager stopGyroUpdates];
    motionManager=nil;
    
    CLLocationManager *locationManager = [LBLocationTracker sharedLocationManager];
    [locationManager stopUpdatingLocation];
    
    NSLog(@"locationManager stop Updating after 10 seconds");
}


- (void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error
{
    // NSLog(@"locationManager error:%@",error);
    
    switch([error code])
    {
        case kCLErrorNetwork: // general, network-related error
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please check your network connection." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        case kCLErrorDenied:{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enable Location Service" message:@"You have to enable the Location Service to use this App. To enable, please go to Settings->Privacy->Location Services" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        default:
        {
            
        }
            break;
    }
}


@end




@implementation LBLocationTracker (Network)

//Send the location to Server
- (void)uploadLocationToServer {
    
    NSLog(@"updateLocationToServer");
    
    // Find the best location from the array based on accuracy
    NSMutableDictionary * myBestLocation = [[NSMutableDictionary alloc]init];
    
    for(int i=0;i<self.scheduler.myLocationArray.count;i++){
        NSMutableDictionary * currentLocation = [self.scheduler.myLocationArray objectAtIndex:i];
        
        if(i==0)
            myBestLocation = currentLocation;
        else{
            if([[currentLocation objectForKey:ACCURACY]floatValue]<=[[myBestLocation objectForKey:ACCURACY]floatValue]){
                myBestLocation = currentLocation;
            }
        }
    }
    NSLog(@"My Best location:%@",myBestLocation);
    
    //If the array is 0, get the last location
    //Sometimes due to network issue or unknown reason, you could not get the location during that  period, the best you can do is sending the last known location to the server
    if(self.scheduler.myLocationArray.count==0)
    {
        NSLog(@"Unable to get location, use the last known location");
        
        self.myLocation=self.myLastLocation;
        self.myLocationAccuracy=self.myLastLocationAccuracy;
        
    }else{
        CLLocationCoordinate2D theBestLocation;
        theBestLocation.latitude =[[myBestLocation objectForKey:LATITUDE]floatValue];
        theBestLocation.longitude =[[myBestLocation objectForKey:LONGITUDE]floatValue];
        self.myLocation=theBestLocation;
        self.myLocationAccuracy =[[myBestLocation objectForKey:ACCURACY]floatValue];
    }
    
    NSLog(@"Send to Server: Latitude(%f) Longitude(%f) Accuracy(%f)",self.myLocation.latitude, self.myLocation.longitude,self.myLocationAccuracy);
    
    
    LBLocationRecord *recordToUpload = [[LBLocationRecord alloc] initWithCLCoordinate2D:CLLocationCoordinate2DMake(self.myLocation.latitude, self.myLocation.longitude) monitoringType:LBForegroundMonitoring];
    
    [LBHTTPClient uploadLocationRecord:recordToUpload onSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success");
    } onFailure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // TODO: save to pending
        [LBPendingDataManager pushPengdingLocation:recordToUpload];
        NSLog(@"failed ");
    }];
    
    [self uploadDeviveInfoToServer];
    
    //After sending the location to the server successful, remember to clear the current array with the following code. It is to make sure that you clear up old location in the array and add the new locations from locationManager
    [self.scheduler.myLocationArray removeAllObjects];
    self.scheduler.myLocationArray = nil;
    self.scheduler.myLocationArray = [[NSMutableArray alloc]init];
}

- (void)uploadDeviveInfoToServer
{
    NSLog(@"upload device info to server ");
    
    NSMutableArray *sensorRecordsToUpload = [NSMutableArray array];
    
    [coremotionData enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSArray* obj, BOOL *stop) {
        
        
        if ([key isEqualToString:AccelerometerKey]) {
            for (CMDeviceMotion *motion  in obj) {
                LBAccelerateRecord *acc = [[LBAccelerateRecord alloc] initWithDeviceMotion:motion];
                [sensorRecordsToUpload addObject:acc];
            }
        }
        
        if ([key isEqualToString:GravityKey]) {
            for (CMDeviceMotion *motion  in obj) {
                LBGravityRecord *grav = [[LBGravityRecord alloc] initWithDeviceMotion:motion];
                [sensorRecordsToUpload addObject:grav];
            }
        }
        
        if ([key isEqualToString:GyroscopeKey]) {
            for (CMGyroData *data  in obj) {
                LBGyroRecord *gyro = [[LBGyroRecord alloc] initWithCMGyroData:data];
                [sensorRecordsToUpload addObject:gyro];
            }
        }
        
        
        if ([key isEqualToString:MagnetometerKey]) {
            for (CMMagnetometerData *data  in obj) {
                LBMagnetometerRecord *mag = [[LBMagnetometerRecord alloc] initWithMagnatometerData:data];
                [sensorRecordsToUpload addObject:mag];
            }
        }
        
    }];
    
    [LBHTTPClient uploadSensorRecords:sensorRecordsToUpload
                            onSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                                NSLog(@"upload sensor success ");
                                coremotionData = nil;
                            }
                            onFailure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                NSLog(@"upload sensor failed ");
                                [LBPendingDataManager pushPengdingSensors:sensorRecordsToUpload];
                                coremotionData = nil;
                            }];
    
}




@end
