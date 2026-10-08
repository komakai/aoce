#include "IOSVideoDevice.hpp"

#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>

#include <vector>

using namespace aoce;
using namespace aoce::ios;

// AVCaptureSession封装,在单独的串行队列里回调每桢数据
@interface AoceCaptureSession : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic, strong) AVCaptureDevice* device;
@property(nonatomic, strong) NSArray<AVCaptureDeviceFormat*>* deviceFormats;
@property(nonatomic, strong) AVCaptureSession* session;
@property(nonatomic, strong) AVCaptureVideoDataOutput* output;
@property(nonatomic, strong) dispatch_queue_t sessionQueue;
@property(nonatomic, strong) dispatch_queue_t videoQueue;
@property(nonatomic, assign) IOSVideoDevice* owner;
@end

@implementation AoceCaptureSession

- (instancetype)initWithDevice:(AVCaptureDevice*)device {
    self = [super init];
    if (self) {
        _device = device;
        _sessionQueue = dispatch_queue_create("aoce.camera.session", DISPATCH_QUEUE_SERIAL);
        _videoQueue = dispatch_queue_create("aoce.camera.video", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (BOOL)openWithFormat:(AVCaptureDeviceFormat*)format fps:(int32_t)fps {
    AVCaptureSession* session = [[AVCaptureSession alloc] init];
    [session beginConfiguration];
    // 使用activeFormat决定分辨率
    session.sessionPreset = AVCaptureSessionPresetInputPriority;
    NSError* error = nil;
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:self.device
                                                                        error:&error];
    if (!input || ![session canAddInput:input]) {
        [session commitConfiguration];
        return NO;
    }
    [session addInput:input];

    AVCaptureVideoDataOutput* output = [[AVCaptureVideoDataOutput alloc] init];
    output.videoSettings = @{
        (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
    };
    output.alwaysDiscardsLateVideoFrames = YES;
    [output setSampleBufferDelegate:self queue:self.videoQueue];
    if (![session canAddOutput:output]) {
        [session commitConfiguration];
        return NO;
    }
    [session addOutput:output];

    if ([self.device lockForConfiguration:&error]) {
        if (format) {
            self.device.activeFormat = format;
        }
        CMTime frameDuration = CMTimeMake(1, fps);
        for (AVFrameRateRange* range in self.device.activeFormat.videoSupportedFrameRateRanges) {
            if (range.minFrameRate <= fps && fps <= range.maxFrameRate) {
                self.device.activeVideoMinFrameDuration = frameDuration;
                self.device.activeVideoMaxFrameDuration = frameDuration;
                break;
            }
        }
        [self.device unlockForConfiguration];
    }
    [session commitConfiguration];

    self.session = session;
    self.output = output;
    dispatch_async(self.sessionQueue, ^{
      [session startRunning];
    });
    return YES;
}

- (void)close {
    AVCaptureSession* session = self.session;
    if (!session) {
        return;
    }
    dispatch_sync(self.sessionQueue, ^{
      [session stopRunning];
    });
    [self.output setSampleBufferDelegate:nil queue:nil];
    // 等待正在处理的视频桢完成,关闭后调用者可能马上清理运算图
    dispatch_sync(self.videoQueue, ^{
                  });
    self.session = nil;
    self.output = nil;
}

- (void)captureOutput:(AVCaptureOutput*)output
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection*)connection {
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (!pixelBuffer || !self.owner) {
        return;
    }
    CMTime time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    int64_t timeStamp = (int64_t)(CMTimeGetSeconds(time) * 1000000000.0);
    self.owner->onFrame((void*)pixelBuffer, timeStamp);
}

@end

namespace aoce {
namespace ios {

static const int32_t kFps = 30;

IOSVideoDevice::IOSVideoDevice(/* args */) {}

IOSVideoDevice::~IOSVideoDevice() {
    close();
    if (capture) {
        AoceCaptureSession* session = (AoceCaptureSession*)CFBridgingRelease(capture);
        session.owner = nullptr;
        capture = nullptr;
    }
}

bool IOSVideoDevice::init(void* devicePtr) {
    AVCaptureDevice* device = (__bridge AVCaptureDevice*)devicePtr;
    AoceCaptureSession* session = [[AoceCaptureSession alloc] initWithDevice:device];
    session.owner = this;
    this->id = device.uniqueID.UTF8String;
    this->name = device.localizedName.UTF8String;
    isBack = device.position == AVCaptureDevicePositionBack;
    // 只列出支持420f(nv12)的格式,每个分辨率只保留一个
    NSMutableArray<AVCaptureDeviceFormat*>* deviceFormats = [NSMutableArray array];
    for (AVCaptureDeviceFormat* format in device.formats) {
        FourCharCode subType = CMFormatDescriptionGetMediaSubType(format.formatDescription);
        if (subType != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
            continue;
        }
        CMVideoDimensions dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        double maxRate = 0;
        for (AVFrameRateRange* range in format.videoSupportedFrameRateRanges) {
            maxRate = MAX(maxRate, range.maxFrameRate);
        }
        bool bExist = false;
        for (const auto& vf : formats) {
            if (vf.width == dims.width && vf.height == dims.height) {
                bExist = true;
                break;
            }
        }
        if (bExist) {
            continue;
        }
        VideoFormat videoFormat = {};
        videoFormat.width = dims.width;
        videoFormat.height = dims.height;
        videoFormat.fps = maxRate >= kFps ? kFps : (int32_t)maxRate;
        videoFormat.videoType = VideoType::nv12;
        videoFormat.index = (int32_t)formats.size();
        formats.push_back(videoFormat);
        [deviceFormats addObject:format];
    }
    session.deviceFormats = deviceFormats;
    capture = (void*)CFBridgingRetain(session);
    if (formats.size() < 1) {
        return false;
    }
    // 默认选择第一个输出格式
    setFormat(0);
    return true;
}

void IOSVideoDevice::setFormat(int32_t index) {
    if (index < 0 || index >= formats.size()) {
        return;
    }
    selectIndex = index;
    selectFormat = formats[index];
}

bool IOSVideoDevice::open() {
    if (!capture) {
        return false;
    }
    if (isOpen) {
        close();
    }
    AoceCaptureSession* session = (__bridge AoceCaptureSession*)capture;
    AVCaptureDeviceFormat* format = nil;
    if (selectIndex >= 0 && selectIndex < session.deviceFormats.count) {
        format = session.deviceFormats[selectIndex];
    }
    if (![session openWithFormat:format fps:selectFormat.fps > 0 ? selectFormat.fps : kFps]) {
        onDeviceAction(VideoHandleId::openFailed, 0);
        return false;
    }
    isOpen = true;
    onDeviceAction(VideoHandleId::open, 0);
    return true;
}

bool IOSVideoDevice::close() {
    if (!isOpen || !capture) {
        return true;
    }
    AoceCaptureSession* session = (__bridge AoceCaptureSession*)capture;
    [session close];
    isOpen = false;
    onDeviceAction(VideoHandleId::close, 0);
    return true;
}

void IOSVideoDevice::onFrame(void* buffer, int64_t timeStamp) {
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)buffer;
    if (CVPixelBufferGetPlaneCount(pixelBuffer) < 2) {
        return;
    }
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    VideoFrame frame = {};
    frame.width = (int32_t)CVPixelBufferGetWidth(pixelBuffer);
    frame.height = (int32_t)CVPixelBufferGetHeight(pixelBuffer);
    frame.timeStamp = timeStamp;
    frame.videoType = VideoType::nv12;
    // Y与UV平面,行宽可能大于width,由getVideoFrame紧密排列
    for (int32_t i = 0; i < 2; i++) {
        frame.data[i] = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, i);
        frame.dataAlign[i] = (int32_t)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, i);
    }
    onVideoFrameAction(frame);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
}

}  // namespace ios
}  // namespace aoce
