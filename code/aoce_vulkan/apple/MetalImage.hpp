#pragma once
#include <vulkan/vulkan.h>

#include <Aoce.hpp>

namespace aoce {
namespace vulkan {

// MoltenVK(VK_EXT_metal_objects)导出MTLTexture,对应android下的HardwareImage
// vulkan运算结果复制到这个image上,外部(MTKView等)直接用对应的MTLTexture显示
bool supportMetalObjects(VkPhysicalDevice physicalDevice);

class MetalImage {
   private:
    /* data */
    VkDevice vkDevice = VK_NULL_HANDLE;
    VkImage vkImage = VK_NULL_HANDLE;
    VkDeviceMemory memory = VK_NULL_HANDLE;
    // id<MTLTexture>
    void* mtlTexture = nullptr;
    ImageFormat format = {};

   public:
    MetalImage(/* args */);
    ~MetalImage();

    void release();

   public:
    inline VkImage getImage() { return vkImage; }
    inline void* getTexture() { return mtlTexture; }
    inline const ImageFormat& getFormat() { return format; }

   public:
    // gpu输出资源创建(rgba8)
    bool createImage(const ImageFormat& format);
};

}  // namespace vulkan
}  // namespace aoce
