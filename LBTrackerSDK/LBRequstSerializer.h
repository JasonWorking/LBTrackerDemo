//
//  LBRequstSerializer.h
//  
//
//  Created by Jason on 15/7/25.
//
//

#import "AFURLRequestSerialization.h"

@class LBInstallation;


typedef NS_ENUM(NSInteger, LBRequestSerializerType) {
    LBInstallationSerializerType = 0,
    LBLeancloudSerializerType = 1,
    
};

// For serialize request of upload objets to leancloud.
@interface LBLeancloudRequestSerializer : AFJSONRequestSerializer
+ (LBLeancloudRequestSerializer *)leancloudSerializerWithInstallation:(LBInstallation *)installation;

@end