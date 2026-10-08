#pragma once

#import <MetalKit/MetalKit.h>

#include "aoce/AoceCore.h"

// 显示aoce输出层(IOutputLayer::outMetalGpuTex)的MTKView,对应android下的GLVideoRender
// 每桢从输出层拿到MTLTexture,按比例(aspect fit)绘制到屏幕上
@interface AoceMetalView : MTKView

// 不持有,由外部保证输出层生命周期长于显示
@property(nonatomic, assign) aoce::IOutputLayer* outputLayer;

- (instancetype)initWithFrame:(CGRect)frame;

// 当前显示的图像(调试/测试用),没有图像返回nil
- (UIImage*)snapshot;

@end
