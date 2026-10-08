#include "AoceManager.hpp"

using namespace aoce;

namespace samples {

void AoceManager::initGraph() {
    pipeGraph = getPipeGraphFactory(GpuType::vulkan)->createGraph();
    layerFactory = getLayerFactory(GpuType::vulkan);
    inputLayer = layerFactory->createInput();
    outputLayer = layerFactory->createOutput();
    yuv2RGBALayer = layerFactory->createYUV2RGBA();
    transposeLayer = layerFactory->createTranspose();
    flipLayer = layerFactory->createFlip();
    reSizeLayer = layerFactory->createSize();

    // iOS后置摄像头输出横屏图像,转置并左右翻转成竖屏
    // (android多一个flipY,是因为opengl纹理坐标上下颠倒)
    TransposeParamet tp = transposeLayer->getParamet();
    tp.bFlipX = 1;
    tp.bFlipY = 0;
    transposeLayer->updateParamet(tp);

    OutputParamet op = outputLayer->getParamet();
    op.bGpu = 1;
    op.bCpu = 0;
    outputLayer->updateParamet(op);
}

void AoceManager::openCamera(bool bFront) {
    if (videoDevice != nullptr && videoDevice->bOpen()) {
        videoDevice->close();
    }
    IVideoManager* videoManager = getVideoManager(CameraType::ios_avfoundation);
    int32_t deviceCount = videoManager->getDeviceCount();
    for (int32_t i = 0; i < deviceCount; i++) {
        videoDevice = videoManager->getDevice(i);
        if (videoDevice->back() != bFront) {
            break;
        }
    }
    if (videoDevice == nullptr) {
        logMessage(LogLevel::warn, "no camera");
        return;
    }
    int32_t formatIndex = videoDevice->findFormatIndex(width, height);
    if (formatIndex < 0) {
        formatIndex = 0;
    }
    videoDevice->setFormat(formatIndex);
    videoFormat = videoDevice->getSelectFormat();
    videoDevice->setObserver(this);
    videoDevice->open();
}

void AoceManager::closeCamera() {
    if (videoDevice != nullptr) {
        videoDevice->close();
    }
}

void AoceManager::initLayers(const std::vector<IBaseLayer*>& baseLayers,
                             bool bAutoIn) {
    pipeGraph->clear();
    extraLayer = pipeGraph->addNode(inputLayer)->addNode(yuv2RGBALayer);
    if (!baseLayers.empty()) {
        for (IBaseLayer* baseLayer : baseLayers) {
            extraLayer = extraLayer->addNode(baseLayer);
        }
        if (bAutoIn) {
            yuv2RGBALayer->getLayer()->addLine(extraLayer, 0, 1);
        }
    }
    extraLayer->addNode(transposeLayer)->addNode(outputLayer);
}

void AoceManager::initLayers(IBaseLayer* blendLayer, IInputLayer* inputLayer1) {
    pipeGraph->clear();
    pipeGraph->addNode(inputLayer)
        ->addNode(yuv2RGBALayer)
        ->addNode(blendLayer)
        ->addNode(transposeLayer)
        ->addNode(outputLayer);
    pipeGraph->addNode(inputLayer1)->addNode(reSizeLayer);
    ReSizeParamet sizeParamet = reSizeLayer->getParamet();
    sizeParamet.newWidth = width;
    sizeParamet.newHeight = height;
    sizeParamet.bLinear = 1;
    reSizeLayer->updateParamet(sizeParamet);
    reSizeLayer->getLayer()->addLine(blendLayer, 0, 1);
}

void AoceManager::clearLayers() { pipeGraph->clear(); }

void AoceManager::onVideoFrame(VideoFrame frame) {
    if (getYuvIndex(frame.videoType) < 0) {
        yuv2RGBALayer->getLayer()->setVisable(false);
    } else {
        if (yuv2RGBALayer->getParamet().type != frame.videoType) {
            yuv2RGBALayer->getLayer()->setVisable(true);
            YUVParamet yp = yuv2RGBALayer->getParamet();
            yp.type = frame.videoType;
            yuv2RGBALayer->updateParamet(yp);
        }
    }
    inputLayer->inputCpuData(frame);
    pipeGraph->run();
}

}  // namespace samples
