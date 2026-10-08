#import "AppDelegate.h"

#import "AoceApp.h"
#import "AutoTestRunner.h"
#import "LayerGroupViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    return YES;
}

- (UISceneConfiguration*)application:(UIApplication*)application
    configurationForConnectingSceneSession:(UISceneSession*)connectingSceneSession
                                   options:(UISceneConnectionOptions*)options {
    UISceneConfiguration* config = [[UISceneConfiguration alloc] initWithName:@"Default"
                                                                  sessionRole:connectingSceneSession.role];
    config.delegateClass = SceneDelegate.class;
    return config;
}

@end

@implementation SceneDelegate

- (void)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
                 options:(UISceneConnectionOptions*)connectionOptions {
    UIWindowScene* windowScene = (UIWindowScene*)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    UINavigationController* navigation = [[UINavigationController alloc]
        initWithRootViewController:[[LayerGroupViewController alloc] init]];
    self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];

    if ([AutoTestRunner enabled]) {
        [AutoTestRunner runWithNavigation:navigation];
        return;
    }
    // 同android的NavigationActivity,启动时申请摄像头权限
    aoceRequestCameraAccess(^(BOOL granted) {
      if (!granted) {
          NSLog(@"aoce: camera access denied");
      }
    });
}

@end
