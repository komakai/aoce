#include "MetalImage.hpp"

#include <cstring>
#include <vector>

#include "../vulkan/VulkanHelper.hpp"
#include "../vulkan/VulkanManager.hpp"

namespace aoce {
namespace vulkan {

bool supportMetalObjects(VkPhysicalDevice physicalDevice) {
    uint32_t count = 0;
    if (vkEnumerateDeviceExtensionProperties(physicalDevice, nullptr, &count,
                                             nullptr) != VK_SUCCESS) {
        return false;
    }
    std::vector<VkExtensionProperties> extensions(count);
    vkEnumerateDeviceExtensionProperties(physicalDevice, nullptr, &count,
                                         extensions.data());
    for (const auto& ext : extensions) {
        if (strcmp(ext.extensionName, VK_EXT_METAL_OBJECTS_EXTENSION_NAME) ==
            0) {
            return true;
        }
    }
    return false;
}

MetalImage::MetalImage(/* args */) {}

MetalImage::~MetalImage() { release(); }

void MetalImage::release() {
    if (vkImage) {
        vkDestroyImage(vkDevice, vkImage, nullptr);
        vkImage = VK_NULL_HANDLE;
    }
    if (memory) {
        vkFreeMemory(vkDevice, memory, nullptr);
        memory = VK_NULL_HANDLE;
    }
    mtlTexture = nullptr;
    format = {};
}

bool MetalImage::createImage(const ImageFormat& imageFormat) {
    release();
    vkDevice = VulkanManager::Get().device;
    format = imageFormat;
    format.imageType = ImageType::rgba8;

    VkExportMetalObjectCreateInfoEXT exportInfo = {};
    exportInfo.sType = VK_STRUCTURE_TYPE_EXPORT_METAL_OBJECT_CREATE_INFO_EXT;
    exportInfo.exportObjectType =
        VK_EXPORT_METAL_OBJECT_TYPE_METAL_TEXTURE_BIT_EXT;

    VkImageCreateInfo imageInfo = {};
    imageInfo.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
    imageInfo.pNext = &exportInfo;
    imageInfo.imageType = VK_IMAGE_TYPE_2D;
    imageInfo.format = VK_FORMAT_R8G8B8A8_UNORM;
    imageInfo.extent = {(uint32_t)format.width, (uint32_t)format.height, 1};
    imageInfo.mipLevels = 1;
    imageInfo.arrayLayers = 1;
    imageInfo.samples = VK_SAMPLE_COUNT_1_BIT;
    imageInfo.tiling = VK_IMAGE_TILING_OPTIMAL;
    imageInfo.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    imageInfo.usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT |
                      VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
                      VK_IMAGE_USAGE_SAMPLED_BIT;
    imageInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    VkResult result = vkCreateImage(vkDevice, &imageInfo, nullptr, &vkImage);
    if (result != VK_SUCCESS) {
        logMessage(LogLevel::error, "metal image: vkCreateImage failed");
        return false;
    }
    VkMemoryRequirements requires = {};
    vkGetImageMemoryRequirements(vkDevice, vkImage, &requires);
    uint32_t memoryTypeIndex = 0;
    if (!getMemoryTypeIndex(requires.memoryTypeBits,
                            VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,
                            memoryTypeIndex)) {
        logMessage(LogLevel::error, "metal image: no memory type");
        release();
        return false;
    }
    VkMemoryAllocateInfo allocInfo = {};
    allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    allocInfo.allocationSize = requires.size;
    allocInfo.memoryTypeIndex = memoryTypeIndex;
    VK_CHECK_RESULT(vkAllocateMemory(vkDevice, &allocInfo, nullptr, &memory));
    VK_CHECK_RESULT(vkBindImageMemory(vkDevice, vkImage, memory, 0));

    auto exportMetalObjects = (PFN_vkExportMetalObjectsEXT)vkGetDeviceProcAddr(
        vkDevice, "vkExportMetalObjectsEXT");
    if (!exportMetalObjects) {
        logMessage(LogLevel::error,
                   "metal image: vkExportMetalObjectsEXT not found");
        release();
        return false;
    }
    VkExportMetalTextureInfoEXT textureInfo = {};
    textureInfo.sType = VK_STRUCTURE_TYPE_EXPORT_METAL_TEXTURE_INFO_EXT;
    textureInfo.image = vkImage;
    textureInfo.plane = VK_IMAGE_ASPECT_PLANE_0_BIT;
    VkExportMetalObjectsInfoEXT objectsInfo = {};
    objectsInfo.sType = VK_STRUCTURE_TYPE_EXPORT_METAL_OBJECTS_INFO_EXT;
    objectsInfo.pNext = &textureInfo;
    exportMetalObjects(vkDevice, &objectsInfo);
    mtlTexture = (void*)textureInfo.mtlTexture;
    if (!mtlTexture) {
        logMessage(LogLevel::error, "metal image: export MTLTexture failed");
        release();
        return false;
    }
    return true;
}

}  // namespace vulkan
}  // namespace aoce
