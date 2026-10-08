#import "MainViewController.h"

#import "AoceApp.h"
#import "AoceMetalView.h"

#include <memory>

#include "AoceManager.hpp"

using namespace samples;

@interface MainViewController ()
@property(nonatomic, strong) AoceMetalView* metalView;
@property(nonatomic, assign) BOOL cameraOpen;
@end

@implementation MainViewController {
    std::unique_ptr<AoceManager> _aoceManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.metalView = [[AoceMetalView alloc] initWithFrame:self.view.bounds];
    self.metalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.metalView];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(onForeground)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(onBackground)
                                               name:UIApplicationDidEnterBackgroundNotification
                                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    aoceRequestCameraAccess(^(BOOL granted) {
      if (!granted) {
          NSLog(@"aoce: camera access denied");
          return;
      }
      [self onForeground];
      [self scheduleSnapshot];
    });
}

// 同android的onStart: 初始化aoce/运算图/网络并打开前置摄像头
- (void)onForeground {
    if (self.cameraOpen) {
        return;
    }
    aoceAppInit();
    if (!_aoceManager) {
        _aoceManager = std::make_unique<AoceManager>();
        _aoceManager->initGraph();
        self.metalView.outputLayer = _aoceManager->getOutputLayer();
    }
    _aoceManager->openCamera(true);
    self.cameraOpen = YES;
}

// 同android的onStop: 关闭摄像头
- (void)onBackground {
    if (_aoceManager && self.cameraOpen) {
        _aoceManager->closeCamera();
        self.cameraOpen = NO;
    }
}

- (void)scheduleSnapshot {
    double delay = [NSUserDefaults.standardUserDefaults doubleForKey:@"AoceSnapshotDelay"];
    if (delay <= 0) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                     UIImage* image = [self.metalView snapshot];
                     NSString* docs = NSSearchPathForDirectoriesInDomains(
                         NSDocumentDirectory, NSUserDomainMask, YES)[0];
                     [UIImagePNGRepresentation(image)
                         writeToFile:[docs stringByAppendingPathComponent:@"snapshot.png"]
                          atomically:YES];
                   });
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
