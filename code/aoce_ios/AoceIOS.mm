#include "AoceIOS.h"

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>

#include <vector>

namespace aoce {
namespace ios {

bool loadImageFile(IInputLayer* inputLayer, const char* filePath) {
    if (inputLayer == nullptr || filePath == nullptr) {
        return false;
    }
    NSURL* url = [NSURL fileURLWithPath:[NSString stringWithUTF8String:filePath]];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, nullptr);
    if (!source) {
        logMessage(LogLevel::warn, std::string("ios image open failed: ") + filePath);
        return false;
    }
    CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, nullptr);
    CFRelease(source);
    if (!image) {
        logMessage(LogLevel::warn, std::string("ios image decode failed: ") + filePath);
        return false;
    }
    int32_t width = (int32_t)CGImageGetWidth(image);
    int32_t height = (int32_t)CGImageGetHeight(image);
    std::vector<uint8_t> data(width * height * 4, 0);
    // 同android Bitmap(ARGB_8888)一样,内存排列为RGBA
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef context =
        CGBitmapContextCreate(data.data(), width, height, 8, width * 4, colorSpace,
                              kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    if (!context) {
        CGImageRelease(image);
        return false;
    }
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGContextRelease(context);
    CGImageRelease(image);

    ImageFormat imageFormat = {};
    imageFormat.width = width;
    imageFormat.height = height;
    imageFormat.imageType = ImageType::rgba8;
    // bSeparateRun为true,inputLayer会复制一份数据
    inputLayer->inputCpuData(data.data(), imageFormat, true);
    return true;
}

}  // namespace ios
}  // namespace aoce
