#include "IOSVideoManager.hpp"

#import <AVFoundation/AVFoundation.h>

#include "IOSVideoDevice.hpp"

namespace aoce {
namespace ios {

IOSVideoManager::IOSVideoManager(/* args */) {}

IOSVideoManager::~IOSVideoManager() {}

void IOSVideoManager::getDevices() {
    videoList.clear();
    AVCaptureDeviceDiscoverySession* discovery = [AVCaptureDeviceDiscoverySession
        discoverySessionWithDeviceTypes:@[
            AVCaptureDeviceTypeBuiltInWideAngleCamera
        ]
                              mediaType:AVMediaTypeVideo
                               position:AVCaptureDevicePositionUnspecified];
    for (AVCaptureDevice* device in discovery.devices) {
        std::shared_ptr<IOSVideoDevice> videoPtr(new IOSVideoDevice());
        if (videoPtr->init((__bridge void*)device)) {
            videoList.push_back(videoPtr);
        }
    }
}

}  // namespace ios
}  // namespace aoce
