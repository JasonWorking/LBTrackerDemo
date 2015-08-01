//
//  LBRequstSerializer.m
//  
//
//  Created by Jason on 15/7/25.
//
//

#import "LBRequstSerializer.h"
#import "LBInstallation.h"

static NSString *const kLeancloudAppID = @"9ra69chz8rbbl77mlplnl4l2pxyaclm612khhytztl8b1f9o";
static NSString *const kLeancloudAppKey = @"1zohz2ihxp9dhqamhfpeaer8nh1ewqd9uephe9ztvkka544b";

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
        [request setValue:kLeancloudAppID forHTTPHeaderField:@"X-AVOSCloud-Application-Id"];
        [request setValue:kLeancloudAppKey forHTTPHeaderField:@"X-AVOSCloud-Application-Key"];
    }
    
    return request;
}




@end







