#pragma once

#include <functional>
#include <memory>
#include <string>
#include <vector>

#include "AoceManager.hpp"
#include "ParametBinder.hpp"
#include "aoce_vulkan_extra/VkExtraExport.h"

namespace samples {

enum class LayerType {
    normal,
    edgeDetection,
    twoInput,
    blend,
};

// 运算层以及(如果是ITLayer<T>)读写参数的接口
struct LayerRef {
    aoce::IBaseLayer* layer = nullptr;
    std::shared_ptr<ParamAccessor> accessor = nullptr;

    LayerRef(aoce::IBaseLayer* baseLayer) : layer(baseLayer) {}
    LayerRef(aoce::ILayer* iLayer) : layer(iLayer->getLayer()) {}
    template <typename T>
    LayerRef(aoce::ITLayer<T>* tLayer)
        : layer(tLayer->getLayer()),
          accessor(std::make_shared<TParamAccessor<T>>(tLayer)) {}
};

struct LayerItem {
    std::string name = "";
    std::string metadata = "";
    // 参数面板调节的是layers[layerIndex]
    int32_t layerIndex = 0;
    std::vector<LayerRef> layers;
    LayerType layerType = LayerType::normal;

    std::vector<aoce::IBaseLayer*> getLayers() const;
    std::shared_ptr<ParamAccessor> getAccessor() const;
};

struct LayerGroup {
    std::string title = "";
    std::vector<LayerItem> layers;

    LayerItem& addItem(const std::string& name, const std::string& metadata,
                       std::vector<LayerRef> layers);
    void addEdgeItem(const std::string& name, const std::string& metadata,
                     LayerRef layer);
    void addTwoItem(const std::string& name, const std::string& metadata,
                    LayerRef layer);
    void addItemLum(const std::string& name, const std::string& metadata,
                    std::vector<LayerRef> layers);
    void addBlendItem(const std::string& name, const std::string& metadata,
                      LayerRef layer);
};

// 所有滤镜分组,对应android/aoceswigtest里的DataManager
class DataManager : public aoce::IMotionDetectorObserver {
   public:
    static DataManager& getInstance();

   private:
    DataManager();
    DataManager(const DataManager&) = delete;
    DataManager& operator=(const DataManager&) = delete;

    void initColorAdjustmentsLayer();
    void initImageProcessingLayer();
    void initBlendingModesLayer();
    void initVisualEffectsLayer();
    void initOpencvLayer();

   private:
    std::unique_ptr<AoceManager> aoceManager = nullptr;
    std::vector<LayerGroup> groups;
    std::function<void(int32_t, int32_t)> motionHandle = nullptr;
    // common layer
    aoce::IBaseLayer* luminanceLayer = nullptr;
    aoce::IBaseLayer* alphaShowLayer = nullptr;
    aoce::IBaseLayer* alphaShowLayer2 = nullptr;
    aoce::IKernelSizeLayer* edgeBoxLayer = nullptr;
    aoce::IInputLayer* inputBlendLayer = nullptr;
    aoce::ILookupLayer* lookupLayer = nullptr;
    aoce::ISoftEleganceLayer* softEleganceLayer = nullptr;
    aoce::IChromaKeyLayer* chromaKeyLayer = nullptr;
    std::string blendImagePath = "blend.png";

   public:
    inline int32_t getGroupCount() { return (int32_t)groups.size(); }
    inline LayerGroup& getIndex(int32_t index) { return groups[index]; }
    inline AoceManager* getAoceManager() { return aoceManager.get(); }

    void openCamera(bool bFront);
    void closeCamera();
    void clearGraph();
    void initLayer(int32_t groupIndex, int32_t layerIndex);
    const std::string& getLayerName(int32_t groupIndex, int32_t layerIndex);
    bool haveParamet(int32_t groupIndex, int32_t layerIndex);
    bool haveMotion(int32_t groupIndex, int32_t layerIndex);
    // 运动检测回调(非主线程)
    inline void setMotionHandle(std::function<void(int32_t, int32_t)> handle) {
        motionHandle = handle;
    }

   public:
    virtual void onMotion(const aoce::vec4& vec) override;
};

}  // namespace samples
