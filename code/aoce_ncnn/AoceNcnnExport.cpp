#include <fstream>
#include <sstream>

#include "CNNHelper.hpp"
#include "FaceDetector.hpp"
#include "FaceKeypointDetector.hpp"
#include "VideoMatting.hpp"
#include "VkNcnnInLayer.hpp"
#include "aoce/AoceManager.hpp"

namespace aoce {

DrawProperty::DrawProperty() {}

DrawProperty::~DrawProperty() {}

void DrawProperty::setDraw(bool bDraw) { this->bDraw = bDraw; }

void DrawProperty::setDraw(int32_t radius, const vec4 color) {
    this->radius = std::max(1, radius);
    this->color = color;
}

int32_t getPixelType(ImageType imageType) {
    switch (imageType) {
        case ImageType::bgra8:
            return ncnn::Mat::PIXEL_BGRA;
        case ImageType::rgba8:
            return ncnn::Mat::PIXEL_RGBA;
        case ImageType::r8:
            return ncnn::Mat::PIXEL_GRAY;
        case ImageType::bgr8:
            return ncnn::Mat::PIXEL_BGR;
        case ImageType::rgb8:
            return ncnn::Mat::PIXEL_RGB;
        default:
            return 0;
    }
}

ncnn::Mat getMat(uint8_t* data, const ImageFormat& inFormat,
                 const ImageFormat& outFormat) {
    ncnn::Mat in = {};
    int32_t inPixel = getPixelType(inFormat.imageType);
    int32_t outPixel = getPixelType(outFormat.imageType);
    if (inPixel > 0) {
        ncnn::Mat::PixelType pixelType = (ncnn::Mat::PixelType)inPixel;
        if (inPixel != outPixel) {
            pixelType = (ncnn::Mat::PixelType)(inPixel | (outPixel << 16));
        }
        if (inFormat.width == outFormat.width &&
            inFormat.height == outFormat.height) {
            in = ncnn::Mat::from_pixels(data, pixelType, inFormat.width,
                                        inFormat.height);
        } else {
            in = ncnn::Mat::from_pixels_resize(data, pixelType, inFormat.width,
                                               inFormat.height, outFormat.width,
                                               outFormat.height);
        }
    }
    return in;
}

int32_t getNetIndex(ncnn::Net* net, const char* blob_name) {
    const std::vector<ncnn::Blob>& blobs = net->blobs();
    for (size_t i = 0; i < blobs.size(); i++) {        
        if (blobs[i].name == blob_name) {
            return i;
        }
    }
    return -1;
}

void testVkMat(ncnn::VkMat& mat) {
#if AOCE_DEBUG_TYPE
    float* data = (float*)mat.mapped_ptr();
    float xx = 0.0f;
    for (int32_t i = 0; i < mat.c; i++) {
        int32_t size = mat.w * mat.h;
        std::vector<float> fd(size, 0.0f);
        memcpy(fd.data(), data + i * size, size);
    }
#endif
}

#if __APPLE__
// A9等老设备上Metal编译器在大核平均池化(如pfld里14x14/7x7)的shader上会卡死,
// 这类层通过featmask(31=16,no vulkan)改用CPU计算
static std::string patchParamForMetal(const std::string& param) {
    std::istringstream input(param);
    std::string result;
    std::string line;
    while (std::getline(input, line)) {
        if (line.compare(0, 7, "Pooling") == 0 &&
            line.find(" 0=1") != std::string::npos &&
            line.find(" 31=") == std::string::npos) {
            size_t pos = line.find(" 1=");
            if (pos != std::string::npos && atoi(line.c_str() + pos + 3) >= 7) {
                line += " 31=16";
            }
        }
        result += line + "\n";
    }
    return result;
}
#endif

int32_t loadNet(ncnn::Net* net, const std::string& paramFile,
                const std::string& modelFile) {
#if defined(__ANDROID__)
    AAssetManager* assetManager = AoceManager::Get().getAppEnv().assetManager;
    assert(assetManager != nullptr);
    int32_t ret = net->load_param(assetManager, paramFile.c_str());
    if (ret == 0) {
        ret = net->load_model(assetManager, modelFile.c_str());
    }
#else
    std::string paramPath = getAocePath() + "/" + paramFile;
    std::string modelPath = getAocePath() + "/" + modelFile;
#if __APPLE__
    std::ifstream paramStream(paramPath);
    std::stringstream paramText;
    paramText << paramStream.rdbuf();
    // load_param_mem不复制字符串,需要在load_param_mem期间有效
    std::string patched = patchParamForMetal(paramText.str());
    int32_t ret = net->load_param_mem(patched.c_str());
#else
    int32_t ret = net->load_param(paramPath.c_str());
#endif
    if (ret == 0) {
        ret = net->load_model(modelPath.c_str());
    }
#endif
    return ret;
}

void copyBuffer(ncnn::Net* net, ncnn::VkMat& dstMat,
                aoce::vulkan::VulkanBuffer* buffer) {
    // ncnn::VkBufferMemory nBuffer = {};
    // nBuffer.buffer = buffer->buffer;
    // nBuffer.memory = buffer->memory;
    // nBuffer.offset = 0;
    // nBuffer.capacity = buffer->getBufferSize();
    // nBuffer.mapped_ptr = buffer->getCpuData();
    // nBuffer.access_flags = VK_ACCESS_SHADER_READ_BIT;
    // nBuffer.stage_flags = VK_PIPELINE_STAGE_TRANSFER_BIT;
    // nBuffer.refcount = 1;

    // const ncnn::VulkanDevice* device = net->vulkan_device();
    // ncnn::VkAllocator* vkallocator = device->acquire_blob_allocator();
    // ncnn::VkCompute cmd(device);
    // ncnn::VkMat nMat(netFormet.width, netFormet.height, 3, &nBuffer, 4,
    //                  vkallocator);
    // ncnn::Option opt = {};
    // opt.blob_vkallocator = vkallocator;
    // opt.workspace_vkallocator = vkallocator;
    // opt.staging_vkallocator = vkallocator;
    // cmd.record_clone(nMat, dstMat, opt);
    // cmd.submit_and_wait();
}

IFaceDetector* createFaceDetector() {
    FaceDetector* detector = new FaceDetector();
    return detector;
}

IFaceKeypointDetector* createFaceKeypointDetector() {
    FaceKeypointDetector* detector = new FaceKeypointDetector();
    return detector;
}

IBaseLayer* createNcnnInLayer() {
    VkNcnnInLayer* layer = new VkNcnnInLayer();
    return layer;
}

INcnnInCropLayer* createNcnnInCropLayer() {
    VkNcnnInCropLayer* layer = new VkNcnnInCropLayer();
    return layer;
}

IVideoMatting* createVideoMatting() {
    VideoMatting* vm = new VideoMatting();
    return vm;
}

IBaseLayer* createNcnnUploadLayer() {
    VkNcnnUploadLayer* layer = new VkNcnnUploadLayer();
    return layer;
}

}  // namespace aoce