#import "LayerGroupViewController.h"

#import "LayerViewController.h"

#include "DataManager.hpp"

using namespace samples;

@interface LayerGroupViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) UISegmentedControl* tabControl;
@property(nonatomic, strong) UITableView* tableView;
@property(nonatomic, assign) NSInteger groupIndex;
@end

@implementation LayerGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"效果展示";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    DataManager& dataManager = DataManager::getInstance();
    NSMutableArray<NSString*>* titles = [NSMutableArray array];
    for (int32_t i = 0; i < dataManager.getGroupCount(); i++) {
        [titles addObject:@(dataManager.getIndex(i).title.c_str())];
    }
    self.tabControl = [[UISegmentedControl alloc] initWithItems:titles];
    self.tabControl.selectedSegmentIndex = 0;
    self.tabControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tabControl addTarget:self
                        action:@selector(onTabChanged:)
              forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.tabControl];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"layer"];
    [self.view addSubview:self.tableView];

    UILayoutGuide* safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.tabControl.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],
        [self.tabControl.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:8],
        [self.tabControl.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-8],
        [self.tableView.topAnchor constraintEqualToAnchor:self.tabControl.bottomAnchor constant:8],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    // 左右滑动切换分组(同ViewPager2)
    UISwipeGestureRecognizer* swipeLeft =
        [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipe:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.tableView addGestureRecognizer:swipeLeft];
    UISwipeGestureRecognizer* swipeRight =
        [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipe:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.tableView addGestureRecognizer:swipeRight];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)selectGroup:(NSInteger)index {
    NSInteger count = DataManager::getInstance().getGroupCount();
    if (index < 0 || index >= count) {
        return;
    }
    self.groupIndex = index;
    self.tabControl.selectedSegmentIndex = index;
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointZero animated:NO];
}

- (void)onTabChanged:(UISegmentedControl*)sender {
    [self selectGroup:sender.selectedSegmentIndex];
}

- (void)onSwipe:(UISwipeGestureRecognizer*)gesture {
    NSInteger step = gesture.direction == UISwipeGestureRecognizerDirectionLeft ? 1 : -1;
    [self selectGroup:self.groupIndex + step];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return DataManager::getInstance().getIndex((int32_t)self.groupIndex).layers.size();
}

- (UITableViewCell*)tableView:(UITableView*)tableView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"layer"
                                                            forIndexPath:indexPath];
    const LayerItem& item =
        DataManager::getInstance().getIndex((int32_t)self.groupIndex).layers[indexPath.row];
    UIListContentConfiguration* content = cell.defaultContentConfiguration;
    content.text = @(item.name.c_str());
    cell.contentConfiguration = content;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LayerViewController* controller =
        [[LayerViewController alloc] initWithGroup:self.groupIndex layer:indexPath.row];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
