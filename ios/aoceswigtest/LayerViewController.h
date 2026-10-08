#pragma once

#import <UIKit/UIKit.h>

@class AoceMetalView;

// 显示一个滤镜的摄像头处理结果,对应android里的LayerActivity
@interface LayerViewController : UIViewController

@property(nonatomic, readonly) AoceMetalView* metalView;
// 不为空时用这张图片代替摄像头(自动化测试/模拟器)
@property(nonatomic, copy) NSString* testImagePath;

- (instancetype)initWithGroup:(NSInteger)groupIndex layer:(NSInteger)layerIndex;

@end
