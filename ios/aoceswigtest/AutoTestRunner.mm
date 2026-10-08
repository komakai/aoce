#import "AutoTestRunner.h"

#import "AoceApp.h"
#import "AoceMetalView.h"
#import "LayerViewController.h"

#include "DataManager.hpp"

using namespace samples;

static FILE* gLogFile = nullptr;

static void autoTestLog(int32_t level, const char* message) {
    NSLog(@"aoce(%d): %s", level, message);
    if (gLogFile) {
        fprintf(gLogFile, "[%d] %s\n", level, message);
        fflush(gLogFile);
    }
}

@interface AutoTestRunner ()
@property(nonatomic, strong) UINavigationController* navigation;
@property(nonatomic, strong) NSString* outDir;
@property(nonatomic, strong) NSMutableArray<NSArray<NSNumber*>*>* queue;
@property(nonatomic, assign) BOOL useCamera;
@end

@implementation AutoTestRunner

static AutoTestRunner* gRunner = nil;

+ (BOOL)enabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:@"AoceAutoTest"];
}

+ (void)runWithNavigation:(UINavigationController*)navigation {
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"AoceAutoTestMVKDebug"]) {
        setenv("MVK_CONFIG_DEBUG", "1", 1);
    }
    gRunner = [[AutoTestRunner alloc] init];
    gRunner.navigation = navigation;
    [gRunner start];
}

- (void)start {
    NSString* docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    self.outDir = [docs stringByAppendingPathComponent:@"autotest"];
    if (![NSUserDefaults.standardUserDefaults stringForKey:@"AoceAutoTestFrom"]) {
        [NSFileManager.defaultManager removeItemAtPath:self.outDir error:nil];
    }
    [NSFileManager.defaultManager createDirectoryAtPath:self.outDir
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
    // MoltenVK的错误信息输出到stderr
    freopen([self.outDir stringByAppendingPathComponent:@"stderr.log"].UTF8String, "a", stderr);
    gLogFile = fopen([self.outDir stringByAppendingPathComponent:@"aoce.log"].UTF8String, "a");
    aoce::setLogAction(autoTestLog);
    self.useCamera = [NSUserDefaults.standardUserDefaults boolForKey:@"AoceAutoTestCamera"];

    DataManager& dataManager = DataManager::getInstance();
    self.queue = [NSMutableArray array];
    NSString* only = [NSUserDefaults.standardUserDefaults stringForKey:@"AoceAutoTestOnly"];
    NSString* from = [NSUserDefaults.standardUserDefaults stringForKey:@"AoceAutoTestFrom"];
    NSArray<NSString*>* fromParts = [from componentsSeparatedByString:@":"];
    int32_t fromIndex = fromParts.count == 2 ? fromParts[0].intValue * 1000 + fromParts[1].intValue : 0;
    for (int32_t g = 0; g < dataManager.getGroupCount(); g++) {
        for (int32_t l = 0; l < dataManager.getIndex(g).layers.size(); l++) {
            if (only && ![only isEqualToString:[NSString stringWithFormat:@"%d:%d", g, l]]) {
                continue;
            }
            if (g * 1000 + l < fromIndex) {
                continue;
            }
            [self.queue addObject:@[ @(g), @(l) ]];
        }
    }
    void (^run)(void) = ^{
      [self next];
    };
    if (self.useCamera) {
        aoceRequestCameraAccess(^(BOOL granted) {
          run();
        });
    } else {
        run();
    }
}

- (void)next {
    if (self.queue.count == 0) {
        autoTestLog(0, "autotest finished");
        [@"done" writeToFile:[self.outDir stringByAppendingPathComponent:@"done.txt"]
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:nil];
        return;
    }
    NSArray<NSNumber*>* item = self.queue.firstObject;
    [self.queue removeObjectAtIndex:0];
    int32_t g = item[0].intValue;
    int32_t l = item[1].intValue;
    std::string name = DataManager::getInstance().getLayerName(g, l);
    autoTestLog(0, [NSString stringWithFormat:@"autotest start %d:%d %s", g, l, name.c_str()].UTF8String);

    LayerViewController* controller = [[LayerViewController alloc] initWithGroup:g layer:l];
    if (!self.useCamera) {
        controller.testImagePath = aoceResourcePath(@"blend.png");
    }
    [self.navigation pushViewController:controller animated:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                     UIImage* image = [controller.metalView snapshot];
                     NSString* file = [self.outDir
                         stringByAppendingPathComponent:[NSString stringWithFormat:@"%d_%02d.png", g, l]];
                     if (image) {
                         [UIImagePNGRepresentation(image) writeToFile:file atomically:YES];
                     } else {
                         autoTestLog(2, [NSString stringWithFormat:@"autotest no image %d:%d", g, l].UTF8String);
                     }
                     [self.navigation popViewControllerAnimated:NO];
                     dispatch_async(dispatch_get_main_queue(), ^{
                       [self next];
                     });
                   });
}

@end
