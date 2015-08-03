//
//  AppDelegate.m
//  Demo
//
//  Created by Jason on 15/8/1.
//  Copyright (c) 2015年 LB. All rights reserved.
//

#import "AppDelegate.h"
#import "WXController.h"
#import <TSMessage.h>
#import "LBTrackerInterface.h"

@interface AppDelegate () <LBTrackerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[WXController alloc] init];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [TSMessage setDefaultViewController: self.window.rootViewController];
    
    [LBTrackerInterface initalizeTrackerWithDelegate:self appID:@"55bc5d8e00b0cb9c40dec37b"];
    
    
    return YES;
}



- (void)trackerDidInitialized;
{
    [LBTrackerInterface startTrackerWithUploadTimeInterval:1*60];
}



- (void)trackerDidFaileToInitializeWithError:(NSError *)error;
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Tips" message:@"LBTracker Init Error, restart your app to retry." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show];
}


@end
