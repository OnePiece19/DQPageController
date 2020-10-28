//
//  DQPageController.h
//  NWN_Component
//
//  Created by HX on 2019/1/2.
//  Copyright © 2019 offcn.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQPageViewLayout.h"

@class DQPageController;

NS_ASSUME_NONNULL_BEGIN

@protocol DQPageControllerDataSource <NSObject>

/// 返回页码控制器总数
- (NSInteger)numberOfControllersInpageController;

/// 代理获每页取控制器
/// @param pageController 翻页控制器
/// @param index 索引
/// @param prefetching 是否为预加载
- (UIViewController *)pageController:(DQPageController *)pageController controllerForIndex:(NSInteger)index prefetching:(BOOL)prefetching;

@end

@protocol DQPageControllerDelegate <NSObject>

@optional

- (void)pageController:(DQPageController *)pageController viewWillAppear:(UIViewController *)viewController forIndex:(NSInteger)index;

- (void)pageController:(DQPageController *)pageController viewDidAppear:(UIViewController *)viewController forIndex:(NSInteger)index;

- (void)pageController:(DQPageController *)pageController viewWillDisappear:(UIViewController *)viewController forIndex:(NSInteger)index;

- (void)pageController:(DQPageController *)pageController viewDidDisappear:(UIViewController *)viewController forIndex:(NSInteger)index;


// Transition animation customization
- (void)pageController:(DQPageController *)pageController transitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex animated:(BOOL)animated;

- (void)pageController:(DQPageController *)pageController transitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress;

- (void)pageController:(DQPageController *)pageController didClickPageViewIndex:(NSInteger)index;

// ScrollViewDelegate
- (void)pageControllerWillBeginScrolling:(DQPageController *)pageController animate:(BOOL)animate;

- (void)pageControllerDidEndScrolling:(DQPageController *)pageController animate:(BOOL)animate;

- (void)pageControllerScrollLeftEndLoadMore:(DQPageController *)pageController;

- (void)pageControllerScrollRightEndLoadMore:(DQPageController *)pageController;

@end


@interface DQPageController : UIViewController

@property (nonatomic, weak, nullable) id<DQPageControllerDataSource> dataSource;

@property (nonatomic, weak, nullable) id<DQPageControllerDelegate>   delegate;

@property (nonatomic, weak, readonly) UIScrollView *scrollView;

@property (nonatomic, strong) DQPageViewLayout<UIViewController *> *layout;
/// 页码总数
@property (nonatomic, assign, readonly) NSInteger countOfControllers;
/// 当前页码
@property (nonatomic, assign, readonly) NSInteger curIndex;
/// 初始页码，默认0
@property (nonatomic, assign) NSInteger firstScrollToIndex;
/// 当前显示的控制器
@property (nonatomic, strong, nullable, readonly) NSArray<UIViewController *> *visibleControllers;

@property (nonatomic, assign) BOOL automaticallySystemManagerViewAppearanceMethods;

@property (nonatomic, assign) UIEdgeInsets contentInset;


/// 滑动到特定的页面
/// @param index 索引
/// @param animate 动画
- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate;

/// 滑动到下一页
/// @param animate 是否显示动画
- (void)scrollToNextPage:(BOOL)animate;

/// 注册控制器类 & 向tableView 一样实现复用
/// @param Class 注册的类
/// @param identifier 标识
- (void)registerClass:(Class)Class forControllerWithReuseIdentifier:(NSString *)identifier;


/// 注册控制器类 & 向tableView 一样实现复用
/// @param nib Class 注册的类
/// @param identifier  标识
- (void)registerNib:(UINib *)nib forControllerWithReuseIdentifier:(NSString *)identifier;


/// 获取对应的控制器类
/// @param identifier 标识
/// @param index 索引
- (nullable __kindof UIViewController *)dequeueReusableControllerWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

//updateData && reloadData
- (void)updateData;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
