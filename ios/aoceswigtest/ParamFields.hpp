#pragma once

#include <cstddef>
#include <typeinfo>

// 参数结构体字段表(由ios/tools/gen_param_fields.py生成),用来代替java里的反射
struct ParamField {
    const std::type_info* owner;
    const char* name;
    const std::type_info* type;
    size_t offset;
};

extern const ParamField kParamFields[];
extern const size_t kParamFieldCount;
