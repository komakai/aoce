#pragma once

// iOS下给app使用的辅助接口,对应android下的JNIHelper/AoceHelper

#include "aoce/AoceCore.h"
#include "aoce/module/ModuleManager.hpp"

#ifndef AOCE_IOS_NCNN
#define AOCE_IOS_NCNN 0
#endif

// iOS下所有模块静态链接(AOCE_USE_STATIC),每个模块由ADD_MODULE导出NewModule_模块名
extern "C" aoce::IModule* NewModule_aoce_ios();
extern "C" aoce::IModule* NewModule_aoce_vulkan();
extern "C" aoce::IModule* NewModule_aoce_vulkan_extra();
#if AOCE_IOS_NCNN
extern "C" aoce::IModule* NewModule_aoce_ncnn();
#endif

namespace aoce {
namespace ios {

// 需要在loadAoce之前调用,app里直接引用各模块,确保静态库里的模块被链接
inline void registerStaticModules() {
    auto& manager = ModuleManager::Get();
    manager.registerModule("aoce_ios", NewModule_aoce_ios);
    manager.registerModule("aoce_vulkan", NewModule_aoce_vulkan);
    manager.registerModule("aoce_vulkan_extra", NewModule_aoce_vulkan_extra);
#if AOCE_IOS_NCNN
    manager.registerModule("aoce_ncnn", NewModule_aoce_ncnn);
#endif
}

// 读取图片文件(png/jpg等)转成rgba8输入给inputLayer,对应JNIHelper.loadBitmap
bool loadImageFile(IInputLayer* inputLayer, const char* filePath);

}  // namespace ios
}  // namespace aoce
