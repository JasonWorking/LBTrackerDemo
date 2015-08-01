//
//  LBTimer.h
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

//LBTimer incorporates 2 timers - referred to as longTimer and shortTimer.
//The longTimer MUST have a longer timer duration than the shortTimer.
//If that is not the case, then the behaviour of LBTimer is indeterminate and unpredictable.
//The shortTimer acts as a 'finer' resolution timer that can be used to update a progressbar or
//continually poll a network connection (for example). It's interval is usually set to a fraction
//of the longTimer.
//
//Example: The longTimer can be set to 2 minutes (i.e. the time to boil an egg). The shortTimer can be
//set to 1 second so the progressbar updates every 1 second. This represents a fraction of 1/120.
//
//LBTimer automatically pauses when the app enters the BACKGROUND and 'unpauses' when the app is
//ACTIVE again.


#import <Foundation/Foundation.h>
@protocol LBTimerDelegate;

@interface LBTimer : NSObject


//The 'finer' resolution timer duration. This must be less than longInterval.
//The behaviour of LBTimer is unpredictable otherwise.
//The units are in seconds. It can be as small as 0.1 milliseconds.
@property float shortInterval;

//The overall timer duration. When this timer expires, then LBTimer deactivates by itself.
//It automatically cleans its memory after deactivating the shortTimer AND longTimer.
//The units are in seconds. It can be as small as 0.1 milliseconds.
@property float longInterval;

//The amount of time in seconds since LBTimer was started
//excluding when the app enters the background state.
@property (nonatomic, readonly) float time;

//The delegate must respond to longTimerExpired: method. This is mandatory.
//It is called when the longTimer expires.
@property(nonatomic, weak) IBOutlet id <LBTimerDelegate> delegate;

//This method is used to initialise LBTimer. LBTimer MUST NOT be initialised using init:
//Initialising LBTimer does not start the timer.
//
//An example:
//  self.LBTimer = [[LBTimer alloc] initWithLongInterval:2*60 andShortInterval:0.5 andDelegate:self];
//
//The above example will create a LBTimer with a longInterval of 120 seconds. It will fire the
//shortTimerExpired: method every 0.5 seconds.
//
//Always allocate LBTimer to the instance variable ONCE (such as in viewDidLoad method). If you need to
//change the settings, stop the timer and then do so using the instance variables
//(i.e. self.LBTimer.longInterval = 3*60;) and then start the timer (i.e. [self.LBTimer start];)
//If you need to deallocate LBTimer, then stop LBTimer first.
//(i.e. [self.LBTimer stop]; self.LBTimer = nil;)
//
//WARNING: If the reference to the newly created LBTimer is changed to point to a BRAND new LBTimer alloc,
//then you must call the 'stopTimer' before reallocating. This is because NSRunLoop keeps a strong reference.
//An example (CORRECT WAY - EVEN THOUGH I RECOMMEND NEVER REALLOCATING):
//  self.LBTimer = [[LBTimer alloc] initWithLongInterval:2*60 andShortInterval:0.5 andDelegate:self]; //First allocation
//  [self.LBTimer stop]; //Even if self.LBTimer is declared as a 'strong' reference, the original does not deallocate
//  self.LBTimer = [[LBTimer alloc] initWithLongInterval:5 andShortInterval:2 andDelegate:self]; //Second BRAND NEW allocation
- (id)initWithLongInterval:(float)longInterval andShortInterval: (float)shortInterval andDelegate:(id <LBTimerDelegate>) delegate;

//Stops the timer. This MUST be called from the same thread that called the startTimer method.
- (void) stopTimer;

//Restarts the timer.
- (void) startTimer;

//Pauses the timer
-(void)pauseTime;

//Unpauses the timer
-(void)unPauseTime;

@end


@protocol LBTimerDelegate <NSObject>

@required
//This method is fired when the longTimer expires. LBTimer will stop at this point. You will need to
//call the startTimer method to restart the timer. It is MANDATORY for the delegate to implement this.
-(void)longTimerExpired: (LBTimer *)gameTimer;

@optional
//This method is fired when the shortTimer expires. It will continue to fire until the longTimer expires,
//at which point LBTimer will stop. It is OPTIONAL for the delegate to implement this.
//In order to update a progressbar, this method should be implemented and used in conjunction with
//the 'time' value and the 'longInterval' value.
//The method is not expected to fire at precise moments. It is only for tasks such as updating, polling etc.
-(void)shortTimerExpired: (LBTimer *)gameTimer time: (float)time longInterval: (float)longInterval;
@end

