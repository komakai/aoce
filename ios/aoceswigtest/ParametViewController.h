#pragma once

#import <UIKit/UIKit.h>

// 根据层的metadata生成的参数调节面板,对应android里的ParametFragment/ParametAdapter
@interface ParametViewController : UIViewController

- (instancetype)initWithGroup:(NSInteger)groupIndex layer:(NSInteger)layerIndex;

@end
