#include "DataManager.hpp"

#import "AoceApp.h"

using namespace aoce;

namespace samples {

std::vector<IBaseLayer*> LayerItem::getLayers() const {
    std::vector<IBaseLayer*> baseLayers;
    for (const auto& ref : layers) {
        baseLayers.push_back(ref.layer);
    }
    return baseLayers;
}

std::shared_ptr<ParamAccessor> LayerItem::getAccessor() const {
    if (layerIndex < 0 || layerIndex >= layers.size()) {
        return nullptr;
    }
    return layers[layerIndex].accessor;
}

LayerItem& LayerGroup::addItem(const std::string& name, const std::string& metadata,
                               std::vector<LayerRef> blayers) {
    LayerItem item = {};
    item.name = name;
    item.metadata = metadata;
    item.layers = blayers;
    layers.push_back(item);
    return layers.back();
}

void LayerGroup::addEdgeItem(const std::string& name, const std::string& metadata,
                             LayerRef layer) {
    addItem(name, metadata, {layer}).layerType = LayerType::edgeDetection;
}

void LayerGroup::addTwoItem(const std::string& name, const std::string& metadata,
                            LayerRef layer) {
    addItem(name, metadata, {layer}).layerType = LayerType::twoInput;
}

void LayerGroup::addItemLum(const std::string& name, const std::string& metadata,
                            std::vector<LayerRef> blayers) {
    addItem(name, metadata, blayers).layerIndex = 1;
}

void LayerGroup::addBlendItem(const std::string& name, const std::string& metadata,
                              LayerRef layer) {
    addItem(name, metadata, {layer}).layerType = LayerType::blend;
}

DataManager& DataManager::getInstance() {
    static DataManager* instance = new DataManager();
    return *instance;
}

DataManager::DataManager() {
    aoceAppInit();
    aoceManager = std::make_unique<AoceManager>();
    aoceManager->initGraph();

    alphaShowLayer = createAlphaShowLayer();
    inputBlendLayer = getLayerFactory(GpuType::vulkan)->createInput();
    alphaShowLayer2 = createAlphaShow2Layer();
    edgeBoxLayer = createBoxFilterLayer(ImageType::r8);
    KernelSizeParamet kernelSizeParamet = edgeBoxLayer->getParamet();
    kernelSizeParamet.kernelSizeX = 5;
    kernelSizeParamet.kernelSizeY = 5;
    edgeBoxLayer->updateParamet(kernelSizeParamet);

    initColorAdjustmentsLayer();
    initImageProcessingLayer();
    initBlendingModesLayer();
    initVisualEffectsLayer();
    initOpencvLayer();
}

void DataManager::initColorAdjustmentsLayer() {
    auto brightLayer = createBrightnessLayer();
    auto exposureLayer = createExposureLayer();
    auto contrastLayer = createContrastLayer();
    auto saturationLayer = createSaturationLayer();
    auto gammaLayer = createGammaLayer();
    auto solarizeLayer = createSolarizeLayer();
    auto levelsLayer = createLevelsLayer();
    auto rgbLayer = createRGBLayer();
    auto hueLayer = createHueLayer();
    auto vibranceLayer = createVibranceLayer();
    auto whiteBalanceLayer = createBalanceLayer();
    auto highlightShadowLayer = createHighlightShadowLayer();
    auto highlightShadowTintLayer = createHighlightShadowTintLayer();
    lookupLayer = createLookupLayer();
    softEleganceLayer = createSoftEleganceLayer();
    auto skinToneLayer = createSkinToneLayer();
    auto colorInverLayer = createColorInvertLayer();
    luminanceLayer = createLuminanceLayer();
    auto monochromeLayer = createMonochromeLayer();
    auto falseColorLayer = createFalseColorLayer();
    auto hazeLayer = createHazeLayer();
    auto sepiaLayer = createSepiaLayer();
    auto luminanceThresholdLayer = createLuminanceThresholdLayer();
    auto adaptiveThresholdLayer = createAdaptiveThresholdLayer();
    auto averageLuminanceThresholdLayer = createAverageLuminanceThresholdLayer();
    auto singleHistoramlayer = createHistogramLayer(true);
    auto historamlayer = createHistogramLayer(false);
    chromaKeyLayer = createChromaKeyLayer();
    auto hsbLayer = createHSBLayer();

    LayerGroup layerGroup = {};
    layerGroup.title = "色彩调整";
    layerGroup.addItem("亮度", "brightnessLayer", {brightLayer});
    layerGroup.addItem("曝光度", "exposureLayer", {exposureLayer});
    layerGroup.addItem("对比度", "contrastLayer", {contrastLayer});
    layerGroup.addItem("饱和度", "saturationLayer", {saturationLayer});
    layerGroup.addItem("Gamma", "gammaLayer", {gammaLayer});
    layerGroup.addItem("基于阈值反转颜色", "solarizeLayer", {solarizeLayer});
    layerGroup.addItem("色阶调整", "levelsLayer", {levelsLayer});
    layerGroup.addItem("调整RGB分量", "rgbLayer", {rgbLayer});
    layerGroup.addItem("色调", "hueLayer", {hueLayer});
    layerGroup.addItem("鲜艳度", "vibranceLayer", {vibranceLayer});
    layerGroup.addItem("白平衡", "whiteBalanceLayer", {whiteBalanceLayer});
    layerGroup.addItem("阴影与高光", "highlightShadowLayer", {highlightShadowLayer});
    layerGroup.addItem("基于颜色和强度的阴影与高光", "highlightShadowTintLayer",
                       {highlightShadowTintLayer});
    layerGroup.addItem("Amatorka滤镜(Lookup)", "lookupLayer", {lookupLayer});
    layerGroup.addItem("MissEtikate滤镜(Lookup)", "lookupLayer", {lookupLayer});
    layerGroup.addItem("SoftElegance滤镜(Lookup)", "softEleganceLayer", {softEleganceLayer});
    layerGroup.addItem("肤色调整滤镜", "skinToneLayer", {skinToneLayer});
    layerGroup.addItem("反转图像", "colorInverLayer", {colorInverLayer});
    layerGroup.addItem("灰度", "luminanceLayer", {luminanceLayer, alphaShowLayer});
    layerGroup.addItem("基于亮度的单色", "monochromeLayer", {monochromeLayer});
    layerGroup.addItem("基于亮度的混合", "falseColorLayer", {falseColorLayer});
    layerGroup.addItem("调整雾度", "hazeLayer", {hazeLayer});
    layerGroup.addItem("棕褐色调", "sepiaLayer", {sepiaLayer});
    layerGroup.addItem("基于亮度的阈值", "luminanceThresholdLayer",
                       {luminanceThresholdLayer, alphaShowLayer});
    layerGroup.addItem("基于周边平均亮度自适应阈值", "adaptiveThresholdLayer",
                       {adaptiveThresholdLayer, alphaShowLayer});
    layerGroup.addItem("基于全图平均亮度的阈值", "averageLuminanceThresholdLayer",
                       {averageLuminanceThresholdLayer, alphaShowLayer});
    layerGroup.addItem("直方图", "historamlayer", {historamlayer, alphaShowLayer});
    layerGroup.addItem("直方图(单通道)", "historamlayer",
                       {luminanceLayer, singleHistoramlayer, alphaShowLayer});
    layerGroup.addItem("色度扣像", "chromaKeyLayer", {chromaKeyLayer, alphaShowLayer});
    layerGroup.addItem("色相/饱和度/亮度", "hsbLayer", {hsbLayer});
    groups.push_back(layerGroup);
}

void DataManager::initImageProcessingLayer() {
    auto sharpenLayer = createSharpenLayer();
    auto unsharpMaskLayer = createUnsharpMaskLayer();
    auto gaussianBlurLayer = createGaussianBlurLayer(ImageType::rgba8);
    auto boxBlurLayer = createBoxFilterLayer(ImageType::rgba8);
    auto blurSelectiveLayer = createBlurSelectiveLayer();
    auto blurPositionLayer = createBlurPositionLayer();
    auto iosBlurLayer = createIOSBlurLayer();
    auto medialLayer = createMedianK3Layer(false);
    auto bilateralLayer = createBilateralLayer();
    auto tiltShiftLayer = createTiltShiftLayer();
    auto sobelEdgeDetectionLayer = createSobelEdgeDetectionLayer();
    auto prewittEdgeDetectionLayer = createPrewittEdgeDetectionLayer();
    auto thresholdEdgeDetectionLayer = createThresholdEdgeDetectionLayer(true);
    auto cannyEdgeDetectionLayer = createCannyEdgeDetectionLayer();
    auto harrisCornerDetectionLayer = createHarrisCornerDetectionLayer();
    auto nobleCornerDetectionLayer = createNobleCornerDetectionLayer();
    auto shiTomasiDetectionLayer = createShiTomasiFeatureDetectionLayer();
    auto fastFeatureLayer = createColourFASTFeatureDetector();
    auto dilationLayer = createDilationLayer(false);
    auto erosionLayer = createErosionLayer(false);
    auto closingLayer = createClosingLayer(false);
    auto openingLayer = createOpeningLayer(false);
    auto singleDilationLayer = createDilationLayer(true);
    auto singleErosionLayer = createErosionLayer(true);
    auto singleClosingLayer = createClosingLayer(true);
    auto singleOpeningLayer = createOpeningLayer(true);
    auto colorLBPLayer = createColorLBPLayer();
    auto lowPassLayer = createLowPassLayer();
    auto highPassLayer = createHighPassLayer();
    auto motionDetectorLayer = createMotionDetectorLayer();
    motionDetectorLayer->setObserver(this);
    auto motionBlurLayer = createMotionBlurLayer();
    auto zoomBlurLayer = createZoomBlurLayer();
    auto guidedLayer = createGuidedLayer();
    auto laplacianLayer = createLaplacianLayer(false);

    LayerGroup layerGroup = {};
    layerGroup.title = "图像处理";
    layerGroup.addItem("锐化图像", "sharpenLayer", {sharpenLayer});
    layerGroup.addItem("模糊蒙版", "unsharpMaskLayer", {unsharpMaskLayer});
    layerGroup.addItem("高斯模糊", "gaussianBlurLayer", {gaussianBlurLayer});
    layerGroup.addItem("Box模糊", "boxBlurLayer", {boxBlurLayer});
    layerGroup.addItem("特定圆形区域清晰", "blurSelectiveLayer", {blurSelectiveLayer});
    layerGroup.addItem("特定圆形区域模糊", "blurPositionLayer", {blurPositionLayer});
    layerGroup.addItem("IOS模糊", "iosBlurLayer", {iosBlurLayer});
    layerGroup.addItem("中值模糊", "medialLayer", {medialLayer});
    layerGroup.addItem("双边滤波", "bilateralLayer", {bilateralLayer});
    layerGroup.addItem("模拟倾斜移位镜头效果", "tiltShiftLayer", {tiltShiftLayer});
    layerGroup.addItemLum("Sobel边缘检测", "sobelEdgeDetectionLayer",
                          {luminanceLayer, sobelEdgeDetectionLayer, alphaShowLayer});
    layerGroup.addItemLum("Prewitt边缘检测", "prewittEdgeDetectionLayer",
                          {luminanceLayer, prewittEdgeDetectionLayer, alphaShowLayer});
    layerGroup.addItemLum("Sobel边缘阈值检测", "thresholdEdgeDetectionLayer",
                          {luminanceLayer, thresholdEdgeDetectionLayer, alphaShowLayer});
    layerGroup.addItem("Canny边缘阈值检测", "cannyEdgeDetectionLayer",
                       {cannyEdgeDetectionLayer, alphaShowLayer});
    layerGroup.addEdgeItem("Harris角点检测", "harrisCornerDetectionLayer",
                           harrisCornerDetectionLayer);
    layerGroup.addEdgeItem("Noble角点检测", "nobleCornerDetectionLayer",
                           nobleCornerDetectionLayer);
    layerGroup.addEdgeItem("Shi-Tomasi角点检测", "nobleCornerDetectionLayer",
                           shiTomasiDetectionLayer);
    layerGroup.addItem("ColourFAST特征描述", "fastFeatureLayer", {fastFeatureLayer});
    layerGroup.addItem("膨胀图像", "dilationLayer", {dilationLayer});
    layerGroup.addItem("腐蚀图像", "erosionLayer", {erosionLayer});
    layerGroup.addItem("先膨胀后腐蚀(闭运算)", "closingLayer", {closingLayer});
    layerGroup.addItem("先腐蚀后膨胀(开运算)", "openingLayer", {openingLayer});
    layerGroup.addItemLum("膨胀图像(单通道)", "dilationLayer",
                          {luminanceLayer, singleDilationLayer, alphaShowLayer});
    layerGroup.addItemLum("腐蚀图像(单通道)", "erosionLayer",
                          {luminanceLayer, singleErosionLayer, alphaShowLayer});
    layerGroup.addItemLum("先膨胀后腐蚀(单通道)", "closingLayer",
                          {luminanceLayer, singleClosingLayer, alphaShowLayer});
    layerGroup.addItemLum("先腐蚀后膨胀(单通道)", "openingLayer",
                          {luminanceLayer, singleOpeningLayer, alphaShowLayer});
    layerGroup.addItem("LBP像素编码", "colorLBPLayer", {colorLBPLayer});
    layerGroup.addItem("低通滤波器", "lowPassLayer", {lowPassLayer});
    layerGroup.addTwoItem("高通滤波器", "highPassLayer", highPassLayer);
    layerGroup.addItem("运动检测器", "motionDetectorLayer", {motionDetectorLayer});
    layerGroup.addItem("定向运动模糊", "motionBlurLayer", {motionBlurLayer});
    layerGroup.addItem("中心运动模糊", "zoomBlurLayer", {zoomBlurLayer});
    layerGroup.addItem("扣像+导向滤波", "chromaKeyLayer",
                       {chromaKeyLayer, guidedLayer, alphaShowLayer});
    layerGroup.addItem("Laplacian锐化", "laplacianLayer", {laplacianLayer});
    groups.push_back(layerGroup);
}

void DataManager::initBlendingModesLayer() {
    LayerGroup layerGroup = {};
    layerGroup.title = "混合模式";
    layerGroup.addBlendItem("溶解混合", "dissolveBlendLayer", createDissolveBlendLayer());
    layerGroup.addBlendItem("多次混合", "multiplyBlendLayer", createMultiplyBlendLayer());
    layerGroup.addBlendItem("加法混合", "addBlendLayer", createAddBlendLayer());
    layerGroup.addBlendItem("减法混合", "subtractBlendLayer", createSubtractBlendLayer());
    layerGroup.addBlendItem("除法混合", "divideBlendLayer", createDivideBlendLayer());
    layerGroup.addBlendItem("叠加混合", "overlayBlendLayer", createOverlayBlendLayer());
    layerGroup.addBlendItem("分量最小混合", "darkenBlendLayer", createDarkenBlendLayer());
    layerGroup.addBlendItem("分量最大混合", "lightenBlendLayer", createLightenBlendLayer());
    layerGroup.addBlendItem("加深混合", "colorBurnBlendLayer", createColorBurnBlendLayer());
    layerGroup.addBlendItem("减淡混合", "colorDodgeBlendLayer", createColorDodgeBlendLayer());
    layerGroup.addBlendItem("屏幕混合", "screenBlendLayer", createScreenBlendLayer());
    layerGroup.addBlendItem("排除混合", "exclusionBlendLayer", createExclusionBlendLayer());
    layerGroup.addBlendItem("差异混合", "differenceBlendLayer", createDifferenceBlendLayer());
    layerGroup.addBlendItem("强化混合", "hardLightBlendLayer", createHardLightBlendLayer());
    layerGroup.addBlendItem("柔和光混合", "softLightBlendLayer", createSoftLightBlendLayer());
    layerGroup.addBlendItem("Alpha混合", "alphaBlendLayer", createAlphaBlendLayer());
    layerGroup.addBlendItem("图像源混合", "sourceOverBlendLayer", createSourceOverBlendLayer());
    layerGroup.addBlendItem("普通混合", "normalBlendLayer", createNormalBlendLayer());
    layerGroup.addBlendItem("图像混合", "colorBlendLayer", createColorBlendLayer());
    layerGroup.addBlendItem("色调混合", "hueBlendLayer", createHueBlendLayer());
    layerGroup.addBlendItem("饱和度混合", "saturationBlendLayer", createSaturationBlendLayer());
    layerGroup.addBlendItem("亮度混合", "luminosityBlendLayer", createLuminosityBlendLayer());
    layerGroup.addBlendItem("线性刻录混合", "linearBurnBlendLayer", createLinearBurnBlendLayer());
    layerGroup.addBlendItem("泊松混合", "poissonLayer", createPoissonBlendLayer());
    layerGroup.addBlendItem("遮罩显示", "maskLayer", createMaskLayer());
    groups.push_back(layerGroup);
}

void DataManager::initVisualEffectsLayer() {
    auto pixellateLayer = createPixellateLayer();
    auto polarPixellateLayer = createPolarPixellateLayer();
    auto pixellatePositionLayer = createPixellatePositionLayer();
    auto polkaDotLayer = createPolkaDotLayer();
    auto halftoneLayer = createHalftoneLayer();
    auto crosshatchLayer = createCrosshatchLayer();
    auto sketchLayer = createSketchLayer();
    auto thresholdSketchLayer = createThresholdSketchLayer(true);
    auto toonLayer = createToonLayer();
    auto smoothToonLayer = createSmoothToonLayer();
    auto embossLayer = createEmbossLayer();
    auto posterizeLayer = createPosterizeLayer();
    auto swirlLayer = createSwirlLayer();
    auto bulgeDistortionLayer = createBulgeDistortionLayer();
    auto pinchDistortionLayer = createPinchDistortionLayer();
    auto stretchDistortionLayer = createStretchDistortionLayer();
    auto sphereRefractionLayer = createSphereRefractionLayer();
    auto glassSphereLayer = createGlassSphereLayer();
    auto vignetteLayer = createVignetteLayer();
    auto kuwaharaLayer = createKuwaharaLayer();
    kuwaharaLayer->updateParamet(3);
    auto cgaColorspaceLayer = createCGAColorspaceLayer();

    LayerGroup layerGroup = {};
    layerGroup.title = "视觉效果";
    layerGroup.addItem("像素化", "pixellateLayer", {pixellateLayer});
    layerGroup.addItem("极坐标像素化", "polarPixellateLayer", {polarPixellateLayer});
    layerGroup.addItem("圆形区域像素化", "pixellatePositionLayer", {pixellatePositionLayer});
    layerGroup.addItem("网格化", "polkaDotLayer", {polkaDotLayer});
    layerGroup.addItem("半色调效果", "pixellateLayer", {halftoneLayer});
    layerGroup.addItem("黑白交叉阴影", "crosshatchLayer", {crosshatchLayer});
    layerGroup.addItemLum("草图", "sketchLayer", {luminanceLayer, sketchLayer, alphaShowLayer});
    layerGroup.addItemLum("草图阈值化", "thresholdSketchLayer",
                          {luminanceLayer, thresholdSketchLayer, alphaShowLayer});
    layerGroup.addItem("卡通", "toonLayer", {toonLayer});
    layerGroup.addItem("平滑卡通", "smoothToonLayer", {smoothToonLayer});
    layerGroup.addItem("压纹效果", "embossLayer", {embossLayer});
    layerGroup.addItem("卡通阴影", "posterizeLayer", {posterizeLayer});
    layerGroup.addItem("涡形失真", "swirlLayer", {swirlLayer});
    layerGroup.addItem("凸起失真", "bulgeDistortionLayer", {bulgeDistortionLayer});
    layerGroup.addItem("变形", "bulgeDistortionLayer", {pinchDistortionLayer});
    layerGroup.addItem("拉伸变形", "stretchDistortionLayer", {stretchDistortionLayer});
    layerGroup.addItem("球体折射", "sphereRefractionLayer", {sphereRefractionLayer});
    layerGroup.addItem("球体反射", "sphereRefractionLayer", {glassSphereLayer});
    layerGroup.addItem("渐晕效果", "vignetteLayer", {vignetteLayer});
    layerGroup.addItem("油画效果", "kuwaharaLayer", {kuwaharaLayer});
    layerGroup.addItem("模拟CGA颜色空间", "cgaColorspaceLayer", {cgaColorspaceLayer});
    groups.push_back(layerGroup);
}

void DataManager::initOpencvLayer() {
    auto equalizeHistLayer = createEqualizeHistLayer(false);
    auto singleEqualizeHistLayer = createEqualizeHistLayer(true);

    LayerGroup layerGroup = {};
    layerGroup.title = "Opencv";
    layerGroup.addItem("直方图均衡化", "equalizeHistLayer", {equalizeHistLayer});
    layerGroup.addItemLum("直方图均衡化(单通道)", "equalizeHistLayer",
                          {luminanceLayer, singleEqualizeHistLayer, alphaShowLayer});
    groups.push_back(layerGroup);
}

void DataManager::openCamera(bool bFront) { aoceManager->openCamera(bFront); }

void DataManager::closeCamera() { aoceManager->closeCamera(); }

void DataManager::clearGraph() { aoceManager->clearLayers(); }

void DataManager::initLayer(int32_t groupIndex, int32_t layerIndex) {
    const LayerItem& layerItem = groups[groupIndex].layers[layerIndex];
    if (layerItem.layerType == LayerType::normal) {
        aoceManager->initLayers(layerItem.getLayers(), false);
    } else if (layerItem.layerType == LayerType::edgeDetection) {
        std::vector<IBaseLayer*> layers = layerItem.getLayers();
        layers.insert(layers.begin(), luminanceLayer);
        layers.push_back(edgeBoxLayer->getLayer());
        layers.push_back(alphaShowLayer2);
        aoceManager->initLayers(layers, true);
    } else if (layerItem.layerType == LayerType::twoInput) {
        aoceManager->initLayers(layerItem.getLayers(), true);
    } else if (layerItem.layerType == LayerType::blend) {
        aoceManager->initLayers(layerItem.layers[0].layer, inputBlendLayer);
        aoceLoadImage(inputBlendLayer, @(blendImagePath.c_str()));
    }
    if (layerItem.metadata == "lookupLayer") {
        NSString* filtPath = @"lookup_amatorka.png";
        if (layerItem.name.find("MissEtikate") != std::string::npos) {
            filtPath = @"lookup_miss_etikate.png";
        }
        aoceLoadImage(lookupLayer->getLookUpInputLayer(), filtPath);
    }
    if (layerItem.metadata == "softEleganceLayer") {
        aoceLoadImage(softEleganceLayer->getLookUpInputLayer1(), @"lookup_soft_elegance_1.png");
        aoceLoadImage(softEleganceLayer->getLookUpInputLayer2(), @"lookup_soft_elegance_2.png");
    }
}

const std::string& DataManager::getLayerName(int32_t groupIndex, int32_t layerIndex) {
    return groups[groupIndex].layers[layerIndex].name;
}

bool DataManager::haveParamet(int32_t groupIndex, int32_t layerIndex) {
    const LayerItem& layerItem = groups[groupIndex].layers[layerIndex];
    if (layerItem.metadata.empty()) {
        return false;
    }
    return getLayerMetadata(layerItem.metadata.c_str()) != nullptr;
}

bool DataManager::haveMotion(int32_t groupIndex, int32_t layerIndex) {
    return groups[groupIndex].layers[layerIndex].metadata == "motionDetectorLayer";
}

void DataManager::onMotion(const vec4& vec) {
    if (motionHandle) {
        motionHandle((int32_t)vec.x, (int32_t)vec.y);
    }
}

}  // namespace samples
