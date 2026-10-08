#import "ParametViewController.h"

#include "DataManager.hpp"
#include "ParametBinder.hpp"

using namespace aoce;
using namespace samples;

@interface ParametViewController ()
@property(nonatomic, assign) NSInteger groupIndex;
@property(nonatomic, assign) NSInteger layerIndex;
@property(nonatomic, strong) NSMutableArray<UILabel*>* valueLabels;
@end

@implementation ParametViewController {
    ParametBinder _binder;
}

- (instancetype)initWithGroup:(NSInteger)groupIndex layer:(NSInteger)layerIndex {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _groupIndex = groupIndex;
        _layerIndex = layerIndex;
        _valueLabels = [NSMutableArray array];
        // 同android的DialogFragment,不遮挡后面的视频
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    // 点击面板外关闭
    UIControl* background = [[UIControl alloc] initWithFrame:self.view.bounds];
    background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [background addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:background];

    UIView* panel = [[UIView alloc] init];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.6];
    panel.layer.cornerRadius = 12;
    panel.clipsToBounds = YES;
    [self.view addSubview:panel];

    UIScrollView* scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [panel addSubview:scrollView];

    UIStackView* stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    [scrollView addSubview:stack];

    UILayoutGuide* safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [panel.topAnchor constraintEqualToAnchor:safe.topAnchor constant:50],
        [panel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [panel.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.95],
        [panel.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.6],
        [scrollView.topAnchor constraintEqualToAnchor:panel.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor
                                        constant:16],
        [stack.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor
                                           constant:-16],
        [stack.leadingAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.leadingAnchor
                                            constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.trailingAnchor
                                             constant:-16],
    ]];

    const LayerItem& layerItem =
        DataManager::getInstance().getIndex((int32_t)self.groupIndex).layers[self.layerIndex];
    ILMetadata* metadata = getLayerMetadata(layerItem.metadata.c_str());
    _binder.init(metadata, layerItem.getAccessor());
    const auto& items = _binder.getItems();
    for (size_t i = 0; i < items.size(); i++) {
        [stack addArrangedSubview:[self rowForItem:items[i] index:i]];
    }
}

- (UILabel*)label:(NSString*)text {
    UILabel* label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:15];
    return label;
}

- (UIView*)rowForItem:(const ParamItem&)item index:(size_t)index {
    NSString* text = @(item.metadata->getText());
    float value = _binder.getValue(index);
    if (item.metaType == LayerMetadataType::abool) {
        UIStackView* row = [[UIStackView alloc] init];
        row.axis = UILayoutConstraintAxisHorizontal;
        UISwitch* sw = [[UISwitch alloc] init];
        sw.on = value != 0.0f;
        sw.tag = index;
        [sw addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
        [row addArrangedSubview:[self label:text]];
        [row addArrangedSubview:sw];
        [self.valueLabels addObject:[[UILabel alloc] init]];
        return row;
    }
    UISlider* slider = [[UISlider alloc] init];
    slider.tag = index;
    if (item.metaType == LayerMetadataType::aint) {
        ILIntMetadata* intMeta = getLIntMetadata(item.metadata);
        slider.minimumValue = intMeta->getMinValue();
        slider.maximumValue = intMeta->getMaxValue();
    } else {
        ILFloatMetadata* floatMeta = getLFloatMetadata(item.metadata);
        slider.minimumValue = floatMeta->getMinValue();
        slider.maximumValue = floatMeta->getMaxValue();
    }
    slider.value = value;
    [slider addTarget:self action:@selector(onSlider:) forControlEvents:UIControlEventValueChanged];

    UILabel* valueLabel = [self label:@""];
    valueLabel.textAlignment = NSTextAlignmentRight;
    [valueLabel.widthAnchor constraintEqualToConstant:64].active = YES;
    [self.valueLabels addObject:valueLabel];
    [self updateValueLabel:index value:value];

    UIStackView* top = [[UIStackView alloc] init];
    top.axis = UILayoutConstraintAxisHorizontal;
    [top addArrangedSubview:[self label:text]];
    [top addArrangedSubview:valueLabel];
    UIStackView* row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisVertical;
    row.spacing = 4;
    [row addArrangedSubview:top];
    [row addArrangedSubview:slider];
    return row;
}

- (void)updateValueLabel:(size_t)index value:(float)value {
    const ParamItem& item = _binder.getItems()[index];
    if (item.metaType == LayerMetadataType::aint) {
        self.valueLabels[index].text = [NSString stringWithFormat:@"%d", (int32_t)value];
    } else {
        self.valueLabels[index].text = [NSString stringWithFormat:@"%.2f", value];
    }
}

- (void)onSlider:(UISlider*)slider {
    size_t index = slider.tag;
    float value = slider.value;
    if (_binder.getItems()[index].metaType == LayerMetadataType::aint) {
        value = roundf(value);
    }
    _binder.setValue(index, value);
    [self updateValueLabel:index value:value];
}

- (void)onSwitch:(UISwitch*)sw {
    _binder.setValue(sw.tag, sw.on ? 1.0f : 0.0f);
}

- (void)onClose {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
