#LBTracker Demo
---
后台定时获取位置、CM传感器信息.  


### SDK使用方式




    #import "LBTrackerInterface.h"

    - (BOOL)applicationDidFinishLaunch:... 
    {
        [LBTrackerInterface initalizeTrackerWithDelegate:self appID:@"your app id "];
    }

    #pragma mark  - LBTrackerDelegate
    // SDK Usage
    - (void)trackerDidInitialized
    {
        [LBTrackerInterface startTracker];
    }





### 结构

1. 分三个模块 对外接口层(对外接口)、数据中心(数据采集,数据存储,本地缓存,内存缓存)、网络访问(HTTP访问)


### 进度

1. 接口层  Done 
2. 数据定时上传  Done
3. 数据上传失败保存到本地 下次自动上传 Done
4. 前台查询CoreMotionActivity数据、上传  Done
5. Demo写了一个小天气App

### TODO
1. 代码优化
2. 编成.framework 或 .a 并制作Pod 
3. 后台获取CoreMotionActivity数据尝试 
4. 其他待发现Bug修复





