#pragma once

#include <videodevice/VideoDevice.hpp>

namespace aoce {
namespace ios {

// AVCaptureDevice封装,输出nv12(420f)格式,对应android下的AVideoDevice
class IOSVideoDevice : public VideoDevice {
   private:
    // AoceCaptureSession(Objective-C)
    void* capture = nullptr;

   public:
    IOSVideoDevice(/* args */);
    virtual ~IOSVideoDevice() override;

   public:
    // device: AVCaptureDevice
    bool init(void* device);
    void onFrame(void* pixelBuffer, int64_t timeStamp);

   public:
    // 摄像机有自己特定输出格式
    virtual void setFormat(int32_t index) override;
    // 打开摄像头
    virtual bool open() override;
    // 关闭摄像头
    virtual bool close() override;
};

}  // namespace ios
}  // namespace aoce
