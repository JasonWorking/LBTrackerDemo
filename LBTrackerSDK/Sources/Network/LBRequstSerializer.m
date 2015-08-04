//
//  LBRequstSerializer.m
//  
//
//  Created by Jason on 15/7/25.
//
//

#import "LBRequstSerializer.h"
#import "LBInstallation.h"

static NSString *const kLBSenzAuthIDStringForLog = @"5548eb2ade57fc001b0000010be762a58ac542706a8b817428d9766e";

#pragma mark - Leancloud request serializer


@interface LBLeancloudRequestSerializer  ()

@property (nonatomic, strong) LBInstallation *installation;

@end

@implementation LBLeancloudRequestSerializer

+ (LBLeancloudRequestSerializer *)leancloudSerializerWithInstallation:(LBInstallation *)installation;
{
    
    LBLeancloudRequestSerializer *serializer = [LBLeancloudRequestSerializer serializerWithWritingOptions:NSJSONWritingPrettyPrinted];
    serializer.installation = installation;
    return serializer;
}



- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(id)parameters
                                     error:(NSError *__autoreleasing *)error
{
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dic = [parameters mutableCopy];
        [dic  addEntriesFromDictionary:@{@"installation":[self.installation JSONRepesentation]}];
        parameters = dic;
    }
    NSMutableURLRequest *request = [super requestWithMethod:method URLString:URLString parameters:parameters error:error];
    request.timeoutInterval = 10;
    if (request) {
        [request setValue:kLBSenzAuthIDStringForLog forHTTPHeaderField:@"X-senz-Auth"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    return request;
}




@end







