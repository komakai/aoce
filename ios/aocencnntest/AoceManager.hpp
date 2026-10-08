#pragma once

#include "aoce/AoceCore.h"
#include "aoce_ncnn/AoceNcnnExport.h"

namespace samples {

// 摄像头->yuv2rgba->ncnn人脸检测/关键点检测->画框/画点->输出层
// 对应android/aocencnntest里的AoceManager
class AoceManager : public aoce::IVideoDeviceObserver {
   private:
    aoce::IPipeGraph* pipeGraph = nullptr;
    aoce::LayerFactory* layerFactory = nullptr;
    aoce::IInputLayer* inputLayer = nullptr;
    aoce::IOutputLayer* outputLayer = nullptr;
    aoce::IYUVLayer* yuv2RGBALayer = nullptr;
    aoce::ITransposeLayer* transposeLayerNcnn = nullptr;
    aoce::IVideoDevice* videoDevice = nullptr;
    aoce::VideoFormat videoFormat = {};

    aoce::IFaceDetector* faceDetector = nullptr;
    aoce::IFaceKeypointDetector* faceKeypointDetector = nullptr;
    aoce::IBaseLayer* ncnnInLayer = nullptr;
    aoce::INcnnInCropLayer* ncnnInCropLayer = nullptr;
    aoce::IDrawRectLayer* drawRectLayer = nullptr;
    aoce::IDrawPointsLayer* drawPointsLayer = nullptr;

    int32_t width = 1280;
    int32_t height = 720;

   public:
    void initGraph();
    void openCamera(bool bFront);
    void closeCamera();
    void loadNet();
    void initLayers();
    void clearLayers();
    inline aoce::IOutputLayer* getOutputLayer() { return outputLayer; }

   public:
    virtual void onVideoFrame(aoce::VideoFrame frame) override;
};

}  // namespace samples
