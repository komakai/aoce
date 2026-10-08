#pragma once

#import <Foundation/Foundation.h>

#include "aoce/AoceCore.h"

// 用一张图片模拟摄像头,以固定帧率回调IVideoDeviceObserver::onVideoFrame
// 用于没有摄像头(模拟器)或自动化测试(启动参数 -AoceAutoTest YES)
@interface AoceImageSource : NSObject

- (instancetype)initWithImagePath:(NSString*)path observer:(aoce::IVideoDeviceObserver*)observer;
- (void)start;
// 同步停止,返回后不会再有回调
- (void)stop;

@end
