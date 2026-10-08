#pragma once

#include <cstring>
#include <memory>
#include <typeinfo>
#include <vector>

#include "aoce/AoceCore.h"

// 读写ITLayer<T>参数的类型擦除接口,java里对应getParamet/updateParamet的反射调用
class ParamAccessor {
   public:
    virtual ~ParamAccessor() {}
    virtual const std::type_info& type() const = 0;
    virtual size_t size() const = 0;
    virtual void get(void* data) = 0;
    virtual void set(const void* data) = 0;
};

template <typename T>
class TParamAccessor : public ParamAccessor {
   private:
    aoce::ITLayer<T>* layer = nullptr;

   public:
    explicit TParamAccessor(aoce::ITLayer<T>* layer) : layer(layer) {}

    virtual const std::type_info& type() const override { return typeid(T); }
    virtual size_t size() const override { return sizeof(T); }
    virtual void get(void* data) override {
        T paramet = layer->getParamet();
        memcpy(data, &paramet, sizeof(T));
    }
    virtual void set(const void* data) override {
        T paramet = {};
        memcpy(&paramet, data, sizeof(T));
        layer->updateParamet(paramet);
    }
};

// 一个可调节的参数(metadata里的叶子节点)
struct ParamItem {
    aoce::ILMetadata* metadata = nullptr;
    aoce::LayerMetadataType metaType = aoce::LayerMetadataType::other;
    const std::type_info* valueType = nullptr;
    size_t offset = 0;
};

// 根据层的metadata把参数结构体展开成一列可调节的参数,对应ParametAdapter
class ParametBinder {
   private:
    std::shared_ptr<ParamAccessor> accessor;
    std::vector<uint8_t> data;
    std::vector<ParamItem> items;

   public:
    bool init(aoce::ILMetadata* metadata,
              std::shared_ptr<ParamAccessor> accessor);

    inline const std::vector<ParamItem>& getItems() const { return items; }

    float getValue(size_t index) const;
    // 修改参数并更新到层上
    void setValue(size_t index, float value);

   private:
    void collect(aoce::ILMetadata* metadata, const std::type_info* type,
                 size_t offset);
};
