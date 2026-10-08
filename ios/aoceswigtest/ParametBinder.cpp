#include "ParametBinder.hpp"

#include <cstring>
#include <string>

#include "ParamFields.hpp"

using namespace aoce;

static const ParamField* findField(const std::type_info* owner,
                                   const char* name) {
    for (size_t i = 0; i < kParamFieldCount; i++) {
        const ParamField& field = kParamFields[i];
        if (*field.owner == *owner && strcmp(field.name, name) == 0) {
            return &field;
        }
    }
    return nullptr;
}

bool ParametBinder::init(ILMetadata* metadata,
                         std::shared_ptr<ParamAccessor> paramAccessor) {
    items.clear();
    accessor = paramAccessor;
    if (metadata == nullptr || !accessor) {
        return false;
    }
    data.resize(accessor->size());
    accessor->get(data.data());
    collect(metadata, &accessor->type(), 0);
    return !items.empty();
}

void ParametBinder::collect(ILMetadata* metadata, const std::type_info* type,
                            size_t offset) {
    if (metadata->getLayerType() == LayerMetadataType::agroup) {
        ILGroupMetadata* group = getLGroupMetadata(metadata);
        for (int32_t i = 0; i < group->getCount(); i++) {
            ILMetadata* child = group->getLMetadata(i);
            const ParamField* field = findField(type, child->getParametName());
            if (field == nullptr) {
                std::string message =
                    std::string("no paramet field: ") + child->getParametName();
                logMessage(LogLevel::warn, message.c_str());
                continue;
            }
            collect(child, field->type, offset + field->offset);
        }
    } else {
        ParamItem item = {};
        item.metadata = metadata;
        item.metaType = metadata->getLayerType();
        item.valueType = type;
        item.offset = offset;
        items.push_back(item);
    }
}

float ParametBinder::getValue(size_t index) const {
    const ParamItem& item = items[index];
    const uint8_t* ptr = data.data() + item.offset;
    if (*item.valueType == typeid(float)) {
        return *(const float*)ptr;
    } else if (*item.valueType == typeid(int32_t)) {
        return (float)*(const int32_t*)ptr;
    } else if (*item.valueType == typeid(uint32_t)) {
        return (float)*(const uint32_t*)ptr;
    } else if (*item.valueType == typeid(bool)) {
        return *(const bool*)ptr ? 1.0f : 0.0f;
    }
    return 0.0f;
}

void ParametBinder::setValue(size_t index, float value) {
    const ParamItem& item = items[index];
    uint8_t* ptr = data.data() + item.offset;
    if (*item.valueType == typeid(float)) {
        *(float*)ptr = value;
    } else if (*item.valueType == typeid(int32_t)) {
        *(int32_t*)ptr = (int32_t)value;
    } else if (*item.valueType == typeid(uint32_t)) {
        *(uint32_t*)ptr = (uint32_t)value;
    } else if (*item.valueType == typeid(bool)) {
        *(bool*)ptr = value != 0.0f;
    } else {
        return;
    }
    accessor->set(data.data());
}
