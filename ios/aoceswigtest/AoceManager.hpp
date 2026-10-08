#pragma once

#include <vector>

#include "aoce/AoceCore.h"

namespace samples {

// 摄像头->yuv2rgba->滤镜层->transpose->输出层,对应android/aoceswigtest里的AoceManager
class AoceManager : public aoce::IVideoDeviceObserver {
   private:
    aoce::IPipeGraph* pipeGraph = nullptr;
    aoce::LayerFactory* layerFactory = nullptr;
    aoce::IInputLayer* inputLayer = nullptr;
    aoce::IOutputLayer* outputLayer = nullptr;
    aoce::IYUVLayer* yuv2RGBALayer = nullptr;
    aoce::ITransposeLayer* transposeLayer = nullptr;
    aoce::IFlipLayer* flipLayer = nullptr;
    aoce::IReSizeLayer* reSizeLayer = nullptr;
    aoce::IBaseLayer* extraLayer = nullptr;
    aoce::IVideoDevice* videoDevice = nullptr;
    aoce::VideoFormat videoFormat = {};
    int32_t width = 1280;
    int32_t height = 720;

   public:
    void initGraph();
    void openCamera(bool bFront = false);
    void closeCamera();
    void initLayers(const std::vector<aoce::IBaseLayer*>& baseLayers,
                    bool bAutoIn);
    void initLayers(aoce::IBaseLayer* blendLayer,
                    aoce::IInputLayer* inputLayer1);
    void clearLayers();
    inline aoce::IOutputLayer* getOutputLayer() { return outputLayer; }

   public:
    virtual void onVideoFrame(aoce::VideoFrame frame) override;
};

}  // namespace samples
