#import "LayerViewController.h"

#import "AoceImageSource.h"
#import "AoceMetalView.h"
#import "ParametViewController.h"

#include "DataManager.hpp"

using namespace samples;

@interface LayerViewController ()
@property(nonatomic, assign) NSInteger groupIndex;
@property(nonatomic, assign) NSInteger layerIndex;
@property(nonatomic, strong) AoceMetalView* metalView;
@property(nonatomic, strong) UILabel* layerLabel;
@property(nonatomic, strong) UILabel* motionLabel;
@property(nonatomic, strong) UIButton* backButton;
@property(nonatomic, strong) UIButton* parametButton;
@property(nonatomic, strong) AoceImageSource* imageSource;
@end

@implementation LayerViewController

- (instancetype)initWithGroup:(NSInteger)groupIndex layer:(NSInteger)layerIndex {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _groupIndex = groupIndex;
        _layerIndex = layerIndex;
    }
    return self;
}

- (UIButton*)roundButton:(NSString*)title action:(SEL)action {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:17];
    button.backgroundColor = UIColor.systemPinkColor;
    button.layer.cornerRadius = 28;
    button.layer.shadowOpacity = 0.3;
    button.layer.shadowOffset = CGSizeMake(0, 3);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    [NSLayoutConstraint activateConstraints:@[
        [button.widthAnchor constraintEqualToConstant:56],
        [button.heightAnchor constraintEqualToConstant:56],
    ]];
    return button;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    DataManager& dataManager = DataManager::getInstance();
    int32_t group = (int32_t)self.groupIndex;
    int32_t layer = (int32_t)self.layerIndex;

    self.metalView = [[AoceMetalView alloc] initWithFrame:self.view.bounds];
    self.metalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.metalView.outputLayer = dataManager.getAoceManager()->getOutputLayer();
    [self.view addSubview:self.metalView];

    self.layerLabel = [[UILabel alloc] init];
    self.layerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.layerLabel.text = @(dataManager.getLayerName(group, layer).c_str());
    self.layerLabel.textAlignment = NSTextAlignmentCenter;
    self.layerLabel.textColor = [UIColor colorWithRed:0.0 green:0.87 blue:1.0 alpha:1.0];
    self.layerLabel.font = [UIFont systemFontOfSize:24];
    [self.view addSubview:self.layerLabel];

    self.motionLabel = [[UILabel alloc] init];
    self.motionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.motionLabel.text = @"xy";
    self.motionLabel.textAlignment = NSTextAlignmentCenter;
    self.motionLabel.textColor = UIColor.whiteColor;
    [self.view addSubview:self.motionLabel];

    self.backButton = [self roundButton:@"返回" action:@selector(onBack)];
    self.parametButton = [self roundButton:@"参数" action:@selector(onParamet)];

    UILayoutGuide* safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.layerLabel.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.layerLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [self.layerLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.motionLabel.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [self.motionLabel.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [self.motionLabel.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [self.backButton.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:56],
        [self.backButton.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-56],
        [self.parametButton.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor
                                                          constant:-56],
        [self.parametButton.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-56],
    ]];

    if (!dataManager.haveParamet(group, layer)) {
        self.parametButton.hidden = YES;
    }
    if (!dataManager.haveMotion(group, layer)) {
        self.motionLabel.hidden = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    DataManager& dataManager = DataManager::getInstance();
    __weak LayerViewController* weakSelf = self;
    dataManager.setMotionHandle([weakSelf](int32_t x, int32_t y) {
        dispatch_async(dispatch_get_main_queue(), ^{
          weakSelf.motionLabel.text = [NSString stringWithFormat:@"X:%d Y:%d", x, y];
        });
    });
    dataManager.initLayer((int32_t)self.groupIndex, (int32_t)self.layerIndex);
    if (self.testImagePath) {
        self.imageSource =
            [[AoceImageSource alloc] initWithImagePath:self.testImagePath
                                              observer:dataManager.getAoceManager()];
        [self.imageSource start];
    } else {
        dataManager.openCamera(false);
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    DataManager& dataManager = DataManager::getInstance();
    if (self.imageSource) {
        [self.imageSource stop];
        self.imageSource = nil;
    } else {
        dataManager.closeCamera();
    }
    dataManager.clearGraph();
    dataManager.setMotionHandle(nullptr);
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onParamet {
    ParametViewController* controller =
        [[ParametViewController alloc] initWithGroup:self.groupIndex layer:self.layerIndex];
    [self presentViewController:controller animated:YES completion:nil];
}

@end
