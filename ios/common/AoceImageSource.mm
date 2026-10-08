#import "AoceImageSource.h"

#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>

#include <vector>

@implementation AoceImageSource {
    aoce::IVideoDeviceObserver* _observer;
    std::vector<uint8_t> _data;
    int32_t _width;
    int32_t _height;
    dispatch_queue_t _queue;
    dispatch_source_t _timer;
}

- (instancetype)initWithImagePath:(NSString*)path observer:(aoce::IVideoDeviceObserver*)observer {
    self = [super init];
    if (self) {
        _observer = observer;
        _queue = dispatch_queue_create("aoce.imagesource", DISPATCH_QUEUE_SERIAL);
        [self loadImage:path];
    }
    return self;
}

- (void)loadImage:(NSString*)path {
    CGImageSourceRef source =
        CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], nullptr);
    if (!source) {
        return;
    }
    CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, nullptr);
    CFRelease(source);
    if (!image) {
        return;
    }
    // 和摄像头一样输出横屏1280x720
    _width = 1280;
    _height = 720;
    _data.assign(_width * _height * 4, 0);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef context =
        CGBitmapContextCreate(_data.data(), _width, _height, 8, _width * 4, colorSpace,
                              kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, _width, _height), image);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(image);
}

- (void)start {
    if (_timer || _data.empty()) {
        return;
    }
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, NSEC_PER_SEC / 30, NSEC_PER_MSEC);
    __unsafe_unretained AoceImageSource* weakSelf = self;
    dispatch_source_set_event_handler(_timer, ^{
      [weakSelf onTimer];
    });
    dispatch_resume(_timer);
}

- (void)onTimer {
    aoce::VideoFrame frame = {};
    frame.width = _width;
    frame.height = _height;
    frame.videoType = aoce::VideoType::rgba8;
    frame.data[0] = _data.data();
    frame.dataAlign[0] = _width * 4;
    frame.timeStamp = aoce::getNowTimeStamp();
    _observer->onVideoFrame(frame);
}

- (void)stop {
    if (!_timer) {
        return;
    }
    dispatch_source_cancel(_timer);
    _timer = nil;
    // 等待正在执行的回调结束
    dispatch_sync(_queue, ^{
                  });
}

- (void)dealloc {
    [self stop];
}

@end
