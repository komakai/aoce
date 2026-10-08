#pragma once

#import <UIKit/UIKit.h>

// 设备上的自动化测试: 依次打开每个滤镜,保存显示结果到 Documents/autotest/
// 启动参数:
//   -AoceAutoTest YES          开启
//   -AoceAutoTestCamera YES    使用摄像头(默认用bundle里的blend.png代替摄像头)
//   -AoceAutoTestOnly 1:14     只测试某个分组:序号
//   -AoceAutoTestFrom 1:14     从某个分组:序号继续(保留之前的结果)
//   -AoceAutoTestMVKDebug YES  MoltenVK调试模式(stderr.log里输出生成的Metal代码)
@interface AutoTestRunner : NSObject

+ (BOOL)enabled;
+ (void)runWithNavigation:(UINavigationController*)navigation;

@end
