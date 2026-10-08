#include "AoceManager.hpp"

using namespace aoce;

namespace samples {

void AoceManager::initGraph() {
    pipeGraph = getPipeGraphFactory(GpuType::vulkan)->createGraph();
    layerFactory = getLayerFactory(GpuType::vulkan);
    inputLayer = layerFactory->createInput();
    outputLayer = layerFactory->createOutput();
    yuv2RGBALayer = layerFactory->createYUV2RGBA();
    transposeLayerNcnn = layerFactory->createTranspose();

    faceDetector = createFaceDetector();
    faceKeypointDetector = createFaceKeypointDetector();
    ncnnInLayer = createNcnnInLayer();
    ncnnInCropLayer = createNcnnInCropLayer();
    drawRectLayer = createDrawRectLayer();
    drawPointsLayer = createDrawPointsLayer();

    faceDetector->setDraw(5, {0.0f, 1.0f, 0.0f, 1.0f});
    faceKeypointDetector->setDraw(5, {1.0f, 0.0f, 0.0f, 1.0f});

    // iOS前置摄像头输出横屏图像,直接转置成竖屏(镜像显示)
    TransposeParamet tpNcnn = transposeLayerNcnn->getParamet();
    tpNcnn.bFlipX = 0;
    tpNcnn.bFlipY = 0;
    transposeLayerNcnn->updateParamet(tpNcnn);

    OutputParamet op = outputLayer->getParamet();
    op.bGpu = 1;
    op.bCpu = 0;
    outputLayer->updateParamet(op);

    initLayers();
    loadNet();
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
    width = videoFormat.width;
    height = videoFormat.height;
    videoDevice->setObserver(this);
    videoDevice->open();
}

void AoceManager::closeCamera() {
    if (videoDevice != nullptr) {
        videoDevice->close();
    }
}

void AoceManager::loadNet() {
    faceDetector->initNet(ncnnInLayer, drawRectLayer);
    faceDetector->setFaceKeypointObserver(ncnnInCropLayer);
    faceKeypointDetector->initNet(ncnnInCropLayer, drawPointsLayer);
}

void AoceManager::initLayers() {
    // 先转置成竖屏再做检测,检测网络只认正立的人脸
    // (android里这个transpose在画框之后,对应代码里注释掉的写法)
    pipeGraph->clear();
    IBaseLayer* uprightLayer = pipeGraph->addNode(inputLayer)
                                   ->addNode(yuv2RGBALayer)
                                   ->addNode(transposeLayerNcnn);
    pipeGraph->addNode(ncnnInLayer);
    pipeGraph->addNode(ncnnInCropLayer);
    uprightLayer->addLine(ncnnInLayer);
    uprightLayer->addLine(ncnnInCropLayer->getLayer());
    uprightLayer->addNode(drawRectLayer)
        ->addNode(drawPointsLayer)
        ->addNode(outputLayer);
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
