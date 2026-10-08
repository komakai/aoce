#import "AoceApp.h"

#import <AVFoundation/AVFoundation.h>

#include "aoce_ios/AoceIOS.h"

void aoceAppInit(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      // MoltenVK默认无限等待Metal编译管线,编译服务异常时会卡死,改为超时失败
      setenv("MVK_CONFIG_METAL_COMPILE_TIMEOUT", "5000000000", 0);
      aoce::ios::registerStaticModules();
      aoce::initPlatform();
      aoce::loadAoce();
    });
}

NSString* aoceResourcePath(NSString* relativePath) {
    return [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:relativePath];
}

void aoceRequestCameraAccess(void (^completion)(BOOL granted)) {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        completion(YES);
        return;
    }
    if (status != AVAuthorizationStatusNotDetermined) {
        completion(NO);
        return;
    }
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                             completionHandler:^(BOOL granted) {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                 completion(granted);
                               });
                             }];
}

bool aoceLoadImage(aoce::IInputLayer* inputLayer, NSString* relativePath) {
    return aoce::ios::loadImageFile(inputLayer, aoceResourcePath(relativePath).UTF8String);
}
