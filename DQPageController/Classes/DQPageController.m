//
//  DQPageController.m
//  NWN_Component
//
//  Created by HX on 2019/1/2.
//  Copyright © 2019 offcn.com. All rights reserved.
//

#import "DQPageController.h"
#import "DQPageViewLayout.h"
@interface DQPageController ()<DQPageViewLayoutDataSource, DQPageViewLayoutDelegate>
{
    struct {
        unsigned int viewWillAppearForIndex :1;
        unsigned int viewDidAppearForIndex :1;
        unsigned int viewWillDisappearForIndex :1;
        unsigned int viewDidDisappearForIndex :1;
        
        unsigned int transitionFromIndexToIndex :1;
        unsigned int transitionFromIndexToIndexProgress :1;

        unsigned int didClickPageViewIndex :1;
        
        unsigned int viewDidScroll: 1;
        unsigned int viewWillBeginScrolling: 1;
        unsigned int viewDidEndScrolling: 1;
        
        unsigned int pageControllerScrollLeftEndLoadMore :1;
        unsigned int pageControllerScrollRightEndLoadMore :1;
        
    }_delegateFlags;
    
}

@end

@implementation DQPageController

#pragma mark - Init

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        NSLog(@"DQPageController   init");
    }
    return self;
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self addFixAutoAdjustInsetScrollView];
    [self.view addSubview:self.layout.scrollView];
}
- (void)addFixAutoAdjustInsetScrollView {
    UIView *view = [[UIView alloc]init];
    [self.view addSubview:view];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _layout.scrollView.frame = UIEdgeInsetsInsetRect(self.view.bounds,_contentInset);
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _layout.scrollView.frame = UIEdgeInsetsInsetRect(self.view.bounds,_contentInset);
}
#pragma mark - public

- (void)scrollToNextPage:(BOOL)animate{
    [_layout scrollToNextPage:animate];
}

- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate {
    [_layout scrollToItemAtIndex:index animate:animate];
}

- (void)registerClass:(Class)Class forControllerWithReuseIdentifier:(NSString *)identifier {
    [_layout registerClass:Class forItemWithReuseIdentifier:identifier];
}
- (void)registerNib:(UINib *)nib forControllerWithReuseIdentifier:(NSString *)identifier {
    [_layout registerNib:nib forItemWithReuseIdentifier:identifier];
}
- (UIViewController *)dequeueReusableControllerWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    return [_layout dequeueReusableItemWithReuseIdentifier:identifier forIndex:index];
}

- (void)updateData{
    [_layout updateData];
}

- (void)reloadData{
    [_layout reloadData];
}

#pragma mark - private1

- (void)childViewController:(UIViewController *)childViewController BeginAppearanceTransition:(BOOL)isAppearing animated:(BOOL)animated {
    if (!_automaticallySystemManagerViewAppearanceMethods) {
        [childViewController beginAppearanceTransition:isAppearing animated:animated];
    }
}

- (void)childViewControllerEndAppearanceTransition:(UIViewController *)childViewController {
    if (!_automaticallySystemManagerViewAppearanceMethods) {
        [childViewController endAppearanceTransition];
    }
}

- (void)didClickPageView:(UITapGestureRecognizer *)sender{
    if (_delegateFlags.didClickPageViewIndex) {
        UITapGestureRecognizer *tap = (UITapGestureRecognizer *)sender;
        UIView *view = (UIView *)tap.view;
        NSInteger index = view.tag;
        [_delegate pageController:self didClickPageViewIndex:index];
    }
}

#pragma mark - DQPageViewLayoutDataSource

- (NSInteger)numberOfItemsInpageViewLayout {
    return [_dataSource numberOfControllersInpageController];
}
- (id)pageViewLayout:(DQPageViewLayout *)pageViewLayout itemForIndex:(NSInteger)index prefetching:(BOOL)prefetching {
    UIViewController * viewController = [_dataSource pageController:self controllerForIndex:index prefetching:prefetching];
    if (_delegateFlags.didClickPageViewIndex) {
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didClickPageView:)];
        viewController.view.tag = index;
        [viewController.view addGestureRecognizer:tap];
    }
    return viewController;
}
- (UIView *)pageViewLayout:(DQPageViewLayout *)pageViewLayout viewForItem:(id)item atIndex:(NSInteger)index {
    UIViewController *viewController = item;
    return viewController.view;
}

/**
 添加-控制器viewcontroller、给scrollView添加子view

 @param pageViewLayout 布局对象
 @param item 控制器
 @param index 索引
 */
- (void)pageViewLayout:(DQPageViewLayout *)pageViewLayout addVisibleItem:(id)item atIndex:(NSInteger)index {
    UIViewController *viewController = item;
    // addChildViewController
    [self addChildViewController:viewController];
    [self childViewController:viewController BeginAppearanceTransition:YES animated:YES];

    [pageViewLayout.scrollView addSubview:viewController.view];

    [self childViewControllerEndAppearanceTransition:viewController];
    NSLog(@"添加控制器+ %ld",(long)index);
    [viewController didMoveToParentViewController:self];
    if (_delegateFlags.viewDidAppearForIndex) {
        [_delegate pageController:self viewDidAppear:viewController forIndex:index];
    }
}

/**
 移除-控制器viewcontroller、从scrollView移除view

 @param pageViewLayout 布局对象
 @param item 控制器
 @param index 索引
 */
- (void)pageViewLayout:(DQPageViewLayout *)pageViewLayout removeInVisibleItem:(id)item atIndex:(NSInteger)index {
    UIViewController *viewController = item;
    if (_delegateFlags.viewWillDisappearForIndex) {
        [_delegate pageController:self viewWillDisappear:viewController forIndex:index];
    }
    // removeChildViewController
    NSLog(@"移除控制器- %ld",(long)index);
    [viewController willMoveToParentViewController:nil];
    [self childViewController:viewController BeginAppearanceTransition:NO animated:YES];

    [viewController.view removeFromSuperview];

    [self childViewControllerEndAppearanceTransition:viewController];
    [viewController removeFromParentViewController];
    if (_delegateFlags.viewDidDisappearForIndex) {
        [_delegate pageController:self viewDidDisappear:viewController forIndex:index];
    }
}

#pragma mark - DQPageViewLayoutDelegate
- (void)pageViewLayout:(DQPageViewLayout *)pageViewLayout transitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress {
    if (_delegateFlags.transitionFromIndexToIndexProgress) {
        [_delegate pageController:self transitionFromIndex:fromIndex toIndex:toIndex progress:progress];
    }
}

- (void)pageViewLayout:(DQPageViewLayout *)pageViewLayout transitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex animated:(BOOL)animated{
    if (_delegateFlags.transitionFromIndexToIndex) {
        [_delegate pageController:self transitionFromIndex:fromIndex toIndex:toIndex animated:animated];
    }
}

-(void)pageViewLayoutScrollLeftEndLoadMore:(DQPageViewLayout *)pageViewLayout {
    
    if (_delegateFlags.pageControllerScrollLeftEndLoadMore) {
        [_delegate pageControllerScrollLeftEndLoadMore:self];
    }
}

- (void)pageViewLayoutScrollRightEndLoadMore:(DQPageViewLayout *)pageViewLayout {
    
    if (_delegateFlags.pageControllerScrollRightEndLoadMore) {
        [_delegate pageControllerScrollRightEndLoadMore:self];
    }
}

- (void)pageViewLayoutWillBeginScrollToView:(DQPageViewLayout *)pageViewLayout animate:(BOOL)anima{
    
}
- (void)pageViewLayoutDidEndScrollToView:(DQPageViewLayout *)pageViewLayout animate:(BOOL)animate{
    
}
- (void)pageViewLayoutWillBeginDragging:(DQPageViewLayout *)pageViewLayout{
    
}
- (void)pageViewLayoutDidEndDragging:(DQPageViewLayout *)pageViewLayout willDecelerate:(BOOL)decelerate{
    
}
- (void)pageViewLayoutWillBeginDecelerating:(DQPageViewLayout *)pageViewLayout{
    
}
- (void)pageViewLayoutDidEndDecelerating:(DQPageViewLayout *)pageViewLayout{
    
}
- (void)pageViewLayoutDidEndScrollingAnimation:(DQPageViewLayout *)pageViewLayout{
    
}




#pragma mark - Lazy Loading

- (DQPageViewLayout<UIViewController *> *)layout {
    if (!_layout) {
        UIScrollView *scrollView = [[UIScrollView alloc]init];
        DQPageViewLayout<UIViewController *> *layout = [[DQPageViewLayout alloc]initWithScrollView:scrollView];
        layout.dataSource = self;
        layout.delegate = self;
        layout.adjustScrollViewInset = YES;
        _layout = layout;
    }
    return _layout;
}

#pragma mark - set/get

-(void)setDelegate:(id<DQPageControllerDelegate>)delegate{
    _delegate = delegate;
    _delegateFlags.transitionFromIndexToIndex = [delegate
                                                 respondsToSelector:
                                                 @selector(pageController:transitionFromIndex:toIndex:animated:)];
    _delegateFlags.transitionFromIndexToIndexProgress = [delegate respondsToSelector:@selector(pageController:transitionFromIndex:toIndex:progress:)];
    _delegateFlags.didClickPageViewIndex = [delegate respondsToSelector:@selector(pageController:didClickPageViewIndex:)];
    
    _delegateFlags.pageControllerScrollLeftEndLoadMore = [delegate respondsToSelector:@selector(pageControllerScrollLeftEndLoadMore:)];
    
    _delegateFlags.pageControllerScrollRightEndLoadMore = [delegate respondsToSelector:@selector(pageControllerScrollRightEndLoadMore:)];
}

@synthesize curIndex = _curIndex;

- (NSInteger)curIndex {
    return _layout.curIndex;
}

-(void)setFirstScrollToIndex:(NSInteger)firstScrollToIndex{
    _firstScrollToIndex = firstScrollToIndex;
    _layout.firstScrollToIndex = firstScrollToIndex;
}

- (NSArray<UIViewController *> *)visibleControllers {
    return _layout.visibleItems;
}

@end
