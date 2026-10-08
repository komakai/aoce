#pragma once

#import <Foundation/Foundation.h>

#include "aoce/AoceCore.h"

// 初始化aoce: 注册静态链接的模块并加载,对应android里的
// AoceWrapper.initPlatform()/AoceWrapper.loadAoce(),多次调用只执行一次
void aoceAppInit(void);

// app bundle里资源的完整路径(对应android的assets)
NSString* aoceResourcePath(NSString* relativePath);

// 请求摄像头权限,回调在主线程
void aoceRequestCameraAccess(void (^completion)(BOOL granted));

// 加载bundle里的图片到输入层,对应android的JNIHelper.loadBitmap
bool aoceLoadImage(aoce::IInputLayer* inputLayer, NSString* relativePath);
