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

- (NSInteger)numberOfControllersInpageController;

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

@property (nonatomic, assign, readonly) NSInteger countOfControllers;

@property (nonatomic, assign, readonly) NSInteger curIndex;

@property (nonatomic, assign) NSInteger firstScrollToIndex;

@property (nonatomic, strong, nullable, readonly) NSArray<UIViewController *> *visibleControllers;

@property (nonatomic, assign) BOOL automaticallySystemManagerViewAppearanceMethods;

@property (nonatomic, assign) UIEdgeInsets contentInset;

- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate;

- (void)scrollToNextPage:(BOOL)animate;

// register && dequeue's usage like tableView
- (void)registerClass:(Class)Class forControllerWithReuseIdentifier:(NSString *)identifier;

- (void)registerNib:(UINib *)nib forControllerWithReuseIdentifier:(NSString *)identifier;

- (nullable __kindof UIViewController *)dequeueReusableControllerWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

//updateData && reloadData
- (void)updateData;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
