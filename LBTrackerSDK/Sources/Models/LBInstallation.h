//
//  LBInstallation.h
//  BgTracker
//
//  Created by Jason on 15/7/25.
//  Copyright (c) 2015年 Gong Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBSingleton.h"

extern NSString *const kLBInstallationSaveKey;

@interface LBInstallation : NSObject

@property (nonatomic, copy) NSString *creatAt;
@property (nonatomic, copy) NSString *ID;
@property (nonatomic, copy) NSString *userID;

DEF_SINGLETON;

- (instancetype)initWithDictionary:(NSDictionary *)dic;

- (void)saveToDisk;

+ (BOOL)installationAvaliable;

/*Example: @{@"installation": @{@"__type":@"Pointer",
            @"className":@"_Installation",
            @"objectId":self.ID?:@""}}*/
- (NSDictionary *)JSONRepesentation;

@end
