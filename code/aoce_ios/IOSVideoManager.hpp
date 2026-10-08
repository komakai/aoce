#pragma once

#include "videodevice/VideoManager.hpp"

namespace aoce {
namespace ios {

// AVFoundation摄像头(前后置广角镜头),对应android下的AVideoManager
class IOSVideoManager : public VideoManager {
   public:
    IOSVideoManager(/* args */);
    virtual ~IOSVideoManager() override;

   protected:
    virtual void getDevices() override;
};

}  // namespace ios
}  // namespace aoce
