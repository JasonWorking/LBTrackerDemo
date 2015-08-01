//
//  LBInstallation.m
//  BgTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import "LBInstallation.h"

NSString *const kLBInstallationIDKey = @"kLBInstallationIDKey";
NSString *const kLBInstallationCreatTimeKey = @"kLBInstallationCreatTimeKey";
NSString *const kLBInstallationUserIDKey = @"kLBInstallationUserIDKey";



@interface LBInstallation ()

@end

@implementation LBInstallation

IMP_SINGLETON;

+ (BOOL)installationAvaliable
{
    NSString *ID = [[NSUserDefaults standardUserDefaults] objectForKey:kLBInstallationIDKey];
    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:kLBInstallationUserIDKey];
    NSString *creatAt  = [[NSUserDefaults standardUserDefaults] objectForKey:kLBInstallationCreatTimeKey];
    
    return ID && userID && creatAt;
}


- (instancetype)initWithDictionary:(NSDictionary *)dic;
{
    if (self = [super init]) {
        self.creatAt = dic[@"createdAt"];
        self.ID = dic[@"id"];
        self.userID = dic[@"userId"];
    }
    
    return self;
}


- (void)saveToDisk
{
    [[NSUserDefaults standardUserDefaults] setObject:self.ID forKey:kLBInstallationIDKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.creatAt forKey:kLBInstallationCreatTimeKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.userID forKey:kLBInstallationUserIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (NSDictionary *)JSONRepesentation
{
   return   @{@"__type":@"Pointer",
              @"className":@"_Installation",
              @"objectId":self.ID?:@""};
}


#pragma mark - 

- (NSString *)ID
{
    if (!_ID) {
        NSString *idString = [[NSUserDefaults standardUserDefaults] objectForKey:kLBInstallationIDKey];
        if (idString) {
            _ID = idString;
        }
    }
    return _ID;
}



@end
