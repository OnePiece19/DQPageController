//
//  DQPageViewLayout.m
//  NWN_Component
//
//  Created by HX on 2018/12/28.
//  Copyright © 2018 offcn.com. All rights reserved.
//

#import "DQPageViewLayout.h"
#import <objc/runtime.h>

static char dq_pageeuseIdentifyKey;

@implementation NSObject (DQpageeuseIdentify)

-(NSString *)dq_pageeuseIdentify{
    return objc_getAssociatedObject(self, &dq_pageeuseIdentifyKey);
}

-(void)setDq_pageeuseIdentify:(NSString * _Nullable)dq_pageeuseIdentify{
    objc_setAssociatedObject(self, &dq_pageeuseIdentifyKey, dq_pageeuseIdentify, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


typedef NS_ENUM(NSUInteger, DQpageScrollingDirection) {
    DQpageScrollingNone,
    DQpageScrollingLeft,
    DQpageScrollingRight,
};

typedef NS_ENUM(NSUInteger, DQpageIndexStoreState) {
    DQpageIndexStoreStateNone,
    DQpageIndexStoreStateVisible,
    DQpageIndexStoreStatePrefect,
    DQpageIndexStoreStateCache,
};

NS_INLINE NSRange visibleRangWithOffset(CGFloat offset,CGFloat width, NSInteger maxIndex){
    if (width <= 0) {
        return NSMakeRange(0, 0);
    }
    NSInteger startIndex = offset/width;
    NSInteger endIndex = ceil((offset + width)/width);
    if (startIndex < 0) {
        startIndex = 0;
    } else if (startIndex > maxIndex) {
        startIndex = maxIndex;
    }
    if (endIndex < 0) {
        endIndex = 0;
    }else if (endIndex > maxIndex) {
        endIndex = maxIndex;
    }
    NSUInteger length = endIndex - startIndex;
    return NSMakeRange(startIndex, length);
}

NS_INLINE CGRect frameForItemAtIndex(NSInteger index, CGRect frame){
    return CGRectMake(index * CGRectGetWidth(frame), 0, CGRectGetWidth(frame), CGRectGetHeight(frame));
}

NS_INLINE NSRange prefetchRangeWithVisibleRange(NSRange visibleRange,NSInteger prefetchItemCount, NSInteger  countOfpageItems) {
    if (prefetchItemCount <= 0) {
        return visibleRange;
    }
    NSInteger leftIndex = MAX((NSInteger)visibleRange.location - prefetchItemCount, 0);
    NSInteger rightIndex = MIN(visibleRange.location+visibleRange.length+prefetchItemCount, countOfpageItems);
    return NSMakeRange(leftIndex, rightIndex - leftIndex);
}

@interface DQPageViewLayout<ItemType>()<UIScrollViewDelegate>
{
    CGFloat     _preOffsetX;
    NSInteger   _firstScrollToIndex;
    NSRange     _didLayoutRange;
    CGFloat     _loadMoreOffset;
    
    BOOL        _didReloadData;
    BOOL        _didLayoutSubViews;
    BOOL        _scrollAnimated;
    BOOL        _needLayoutChildItems;
    BOOL        _isTapScrollMoved;
    
    BOOL        _scrollLeftEndMore;
    BOOL        _scrollRightEndMore;
    
    struct {
        unsigned int addVisibleItem :1;
        unsigned int removeInVisibleItem :1;
    }_dataSourceFlags;
    
    struct {
        unsigned int transitionFromIndexToIndex :1;
        unsigned int transitionFromIndexToIndexProgress :1;
        
        unsigned int pageViewLayoutScrollLeftEndLoadMore :1;
        unsigned int pageViewLayoutScrollRightEndLoadMore :1;
        
        unsigned int pageViewLayoutWillBeginScrollToView :1;
        unsigned int pageViewLayoutDidEndScrollToView :1;
        
        unsigned int pageViewLayoutWillBeginDragging :1;
        unsigned int pageViewLayoutDidEndDragging :1;
        
        unsigned int pageViewLayoutWillBeginDecelerating :1;
        unsigned int pageViewLayoutDidEndDecelerating :1;
        
        unsigned int pageViewLayoutDidEndScrollingAnimation :1;
        
    }_delegateFlags;
}

@property (nonatomic, strong) NSMutableDictionary<NSNumber *,ItemType> *visibleIndexItems; // 展示的数组
@property (nonatomic, strong) NSMutableDictionary<NSNumber *,ItemType> *prefetchIndexItems;// 预加载数组

//reuse Class and nib
@property (nonatomic, strong) NSMutableDictionary *reuseIdentifyClassOrNib;
// reuse items
@property (nonatomic, strong) NSMutableDictionary *reuseIdentifyItems;

@end

static NSString * kScrollViewFrameObserverKey = @"scrollView.frame";

@implementation DQPageViewLayout

#pragma mark - Init

-(instancetype)initWithScrollView:(UIScrollView *)scrollView{
    if (self = [super init]) {
        //false 调用当前线程的断点句柄
        NSParameterAssert(scrollView!=nil);
        _scrollView = scrollView;
        [self configurePropertys];
        [self configureScrollView];
        [self addScrollViewObservers];
    }
    return self;
}
#pragma mark - Life Cycle

-(void)dealloc{
    [self removeScrollViewObservers];
}

#pragma mark - Configure

- (void)configurePropertys {
    _curIndex = -1;
    _preOffsetX = NSNotFound;
    _didReloadData = NO;
    _didLayoutSubViews = NO;
    _firstScrollToIndex = 0;
    
    _loadMoreOffset = 25.0f;
    _scrollLeftEndMore = NO;
    _scrollRightEndMore = NO;
    
    // 预取item是否添加到scrollview上
    _prefetchItemWillAddToSuperView = YES;
    _changeIndexWhenScrollProgress = 0.5;
    _progressAnimateEnabel = YES;
    _adjustScrollViewInset = YES;
    _scrollAnimated = YES;
    _needLayoutChildItems = YES;
    _didLayoutRange = NSMakeRange(0, 0);
    _visibleRange = NSMakeRange(NSNotFound, NSNotFound);
}

- (void)configureScrollView {
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.pagingEnabled = YES;
    _scrollView.delegate = self;
}

#pragma mark - Public Methods

- (void)reloadData{
    _countOfpageItems = [_dataSource numberOfItemsInpageViewLayout];
    _visibleRange = NSMakeRange(NSNotFound, NSNotFound);
    _prefetchRange = NSMakeRange(NSNotFound, NSNotFound);
    [self clearMemoryCache];
    [self removeAllItems];
    _needLayoutChildItems = NO;
    [_scrollView setContentOffset:CGPointMake(_firstScrollToIndex * CGRectGetWidth(_scrollView.frame),0) animated:NO];
    _needLayoutChildItems = YES;
    [self layoutChildItems];
}
    


/**
 updateData : update current controller show data and prefect controller data if exist.
              Do not change the current display position.
 */
- (void)updateData{
    _countOfpageItems = [_dataSource numberOfItemsInpageViewLayout];
    _visibleRange = NSMakeRange(NSNotFound, NSNotFound);
    _prefetchRange = NSMakeRange(NSNotFound, NSNotFound);
    [self clearMemoryCache];
    [self removeAllItems];
    [self layoutChildItems];
}


/**
 scroll to item at index
 */
- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate {
    if (index < 0 || index >= _countOfpageItems) {
        if (!_didReloadData && index >= 0) {
            _firstScrollToIndex = index;
        }
        return;
    }
    
    if (!_didLayoutSubViews && CGRectIsEmpty(_scrollView.frame)) {
        _firstScrollToIndex = index;
    }
    [self scrollViewWillScrollToView:_scrollView animate:animate];
    [_scrollView setContentOffset:CGPointMake(index * CGRectGetWidth(_scrollView.frame),0) animated:NO];
    [self scrollViewDidScrollToView:_scrollView animate:animate];
}

- (void)scrollToNextPage:(BOOL)animate{
    [self scrollViewWillScrollToView:_scrollView animate:animate];
    [_scrollView setContentOffset:CGPointMake((_curIndex + 1) * CGRectGetWidth(_scrollView.frame),0) animated:YES];
    [self scrollViewDidScrollToView:_scrollView animate:animate];
}

- (UIView *)viewForItem:(id)item atIndex:(NSInteger)index {
    UIView *view = [_dataSource pageViewLayout:self viewForItem:item atIndex:index];
    return view;
}

- (CGRect)frameForItemAtIndex:(NSInteger)index {
    CGRect frame = frameForItemAtIndex(index, _scrollView.frame);
    if (_adjustScrollViewInset) {
        frame.size.height -= _scrollView.contentInset.top;
    }
    return frame;
}

- (id)itemForIndex:(NSInteger)idx {
    NSNumber *index = @(idx);
    // 1.from visibleViews
    id visibleItem = [_visibleIndexItems objectForKey:index];
    if (!visibleItem && _prefetchItemCount > 0) {
        // 2.from prefetch
        visibleItem = [_prefetchIndexItems objectForKey:index];
    }
    return visibleItem;
}


#pragma mark - Private Methods

- (void)setNeedLayout {
    // 1. get count Of page Items
    if (_countOfpageItems <= 0) {
        _countOfpageItems = [_dataSource numberOfItemsInpageViewLayout];
    }
    if (_curIndex >= _countOfpageItems) {
        _curIndex = _countOfpageItems - 1;
    }
    
    BOOL needLayoutSubViews = NO;
    if (!_didLayoutSubViews && !CGRectIsEmpty(_scrollView.frame) && _firstScrollToIndex < _countOfpageItems) {
        _didLayoutSubViews = YES;
        needLayoutSubViews = YES;
    }
    
    // 2.set contentSize and offset
    CGFloat contentWidth = CGRectGetWidth(_scrollView.frame);
    _scrollView.contentSize = CGSizeMake(_countOfpageItems * contentWidth, 0);
    _scrollView.contentOffset = CGPointMake(MAX(needLayoutSubViews ? _firstScrollToIndex : _curIndex, 0)*contentWidth, _scrollView.contentOffset.y);
    
    // 3.layout content
    if (_curIndex < 0 || needLayoutSubViews) {
        [self scrollViewDidScroll:_scrollView];
    }
}

- (void)layoutChildItems{
    if (CGRectIsEmpty(_scrollView.frame)) {
        return;
    }
    CGFloat offsetX = _scrollView.contentOffset.x;
    NSRange visibleRange = visibleRangWithOffset(offsetX, CGRectGetWidth(_scrollView.frame), _countOfpageItems);
    if (NSEqualRanges(_visibleRange, visibleRange)) {
        return;
    }
    _visibleRange = visibleRange;
    [self addVisibleItemsInVisibleRange:visibleRange];
    [self addPrefetchItemsOutOfVisibleRange:visibleRange];
    [self removeVisibleItemsInVisibleRange:visibleRange];
    [self removeUnVisibleItemsOutOfVisibleRange:visibleRange];
}


- (DQpageScrollingDirection)caculateScrollViewDraggingDirection:(CGFloat)preOffsetX currentOffsetX:(CGFloat)offsetX{
    if (preOffsetX == NSNotFound) {
        return DQpageScrollingNone;
    } else{
        DQpageScrollingDirection direction = offsetX >= preOffsetX ? DQpageScrollingLeft : DQpageScrollingRight;
        return direction;
    }
}

- (DQpageIndexStoreState)caculateIndexState:(NSInteger)index{
    NSNumber *idx = @(index);
    if ([[self.visibleIndexItems allKeys] containsObject:idx]) {
        return DQpageIndexStoreStateVisible;
    }
    if ([[self.prefetchIndexItems allKeys] containsObject:idx]) {
        return DQpageIndexStoreStatePrefect;
    }
    if ([self cacheItemForKey:idx]) {
        return DQpageIndexStoreStateCache;
    }
    return DQpageIndexStoreStateNone;
}

/**
 DQPageViewLayoutDelegate 提供滑动的 fromIndex toIndex progress

 @param offsetX 偏移量
 @param direction 方向
 */
- (void)caculateIndexByProgressWithOffsetX:(CGFloat)offsetX direction:(DQpageScrollingDirection)direction{
    if (CGRectIsEmpty(_scrollView.frame)) {
        return;
    }
    if (_countOfpageItems <= 0) {
        _curIndex = -1;
        return;
    }
    CGFloat width = CGRectGetWidth(_scrollView.frame);
    CGFloat floadIndex = offsetX/width;
    NSInteger floorIndex = floor(floadIndex);
    if (floorIndex < 0 || floorIndex >= _countOfpageItems || floadIndex > _countOfpageItems-1) {
        return;
    }
    
    CGFloat progress = offsetX/width-floorIndex;
    NSInteger fromIndex = 0, toIndex = 0;
    
    if (direction == DQpageScrollingLeft) {
        fromIndex = floorIndex;
        toIndex = MIN(_countOfpageItems -1, fromIndex + 1);
        if (fromIndex == toIndex && toIndex == _countOfpageItems-1) {
            fromIndex = _countOfpageItems-2;
            progress = 1.0;
        }
    }else if (direction == DQpageScrollingRight){
        toIndex = floorIndex;
        fromIndex = MIN(_countOfpageItems-1, toIndex +1);
        progress = 1.0 - progress;
    }else {
        fromIndex = floorIndex;
        toIndex = fromIndex;
        progress = 1.0;
    }
    if (_delegateFlags.transitionFromIndexToIndexProgress) {
        [_delegate pageViewLayout:self transitionFromIndex:fromIndex toIndex:toIndex progress:progress];
    }
}

/**
 计算 页面跳转情况 页面是否改变

 @param offsetX 偏移量
 @param direction 方向
 */
- (BOOL)caculateIndexWithOffsetX:(CGFloat)offsetX direction:(DQpageScrollingDirection)direction{
    if (CGRectIsEmpty(_scrollView.frame)) {
        return NO;
    }
    if (_countOfpageItems <= 0) {
        _curIndex = -1;
        return NO;
    }
    CGFloat width = CGRectGetWidth(_scrollView.frame);
    NSInteger index = 0;
    // when scroll to progress(changeIndexWhenScrollProgress) will change index
    double percentChangeIndex = _changeIndexWhenScrollProgress;
    if (_changeIndexWhenScrollProgress >= 1.0 || [self progressCaculateEnable]) {
        percentChangeIndex = 0.999999999;
    }
    if (direction == DQpageScrollingLeft) {
        index = ceil(offsetX/width-percentChangeIndex);
    }else {
        index = floor(offsetX/width+percentChangeIndex);
    }
    
    if (index < 0) {
        index = 0;
    }else if (index >= _countOfpageItems) {
        index = _countOfpageItems-1;
    }
    if (index == _curIndex) {
        // if index not same,change index
        return NO;
    }else{
        NSInteger fromIndex = MAX(_curIndex, 0);
        _curIndex = index;
        
        if (_delegateFlags.transitionFromIndexToIndex /*&& ![self progressCaculateEnable]*/) {
            [_delegate pageViewLayout:self transitionFromIndex:fromIndex toIndex:_curIndex animated:_scrollAnimated];
        }
        _scrollAnimated = YES;
        return YES;
    }
}

/**
 progress是否可以计算
 1、实现了代理方法
 2、进度有动画
 3、必须是滑动
 @return yes
 */
- (BOOL)progressCaculateEnable {
    return _delegateFlags.transitionFromIndexToIndexProgress && _progressAnimateEnabel && !_isTapScrollMoved;
}


/**
 过滤头尾的布局和弹簧效果的布局

 @return 是否可以布局
 */
- (BOOL)preLayoutChildViewEnable:(DQpageScrollingDirection)direction {
    CGFloat offsetX = _scrollView.contentOffset.x;
    CGFloat scrollContentW = _scrollView.contentSize.width;
    CGFloat scrollFrameW = CGRectGetWidth(_scrollView.frame);
    if (scrollContentW - offsetX < scrollFrameW || offsetX < 0) {
        return NO;
    }
    if (direction == DQpageScrollingNone) {
        return YES;
    }
    if (direction == DQpageScrollingLeft && offsetX > 10) {
        return YES;
    }
    if (direction == DQpageScrollingRight && (_countOfpageItems - 1) * scrollFrameW - offsetX > 10) {
        return YES;
    }
    return NO;
}

/**
 * 滑动到两头再次滑动
 */
- (void)scrollViewToBothEndAndMore:(DQpageScrollingDirection)direction {
    CGFloat offsetX = _scrollView.contentOffset.x;
    CGFloat scrollFrameW = CGRectGetWidth(_scrollView.frame);
    if (direction == DQpageScrollingRight && offsetX < -_loadMoreOffset) {
        _scrollLeftEndMore = YES;
    }
    
    if (direction == DQpageScrollingLeft && (offsetX - (_countOfpageItems - 1) * scrollFrameW  > _loadMoreOffset)) {
        _scrollRightEndMore = YES;
    }
}

/**
 判断是否重叠

 @param willLayRange 将要布局的范围
 @return  返回以外的释放
 */
- (NSInteger)caculateWillLayoutOverLayRange:(NSRange)willLayRange{
    if (_didLayoutRange.length == 0) {
        return NSNotFound;
    }
    if (willLayRange.location >= _didLayoutRange.location + _didLayoutRange.length) {
        return NSNotFound;
    }
    if (willLayRange.location + willLayRange.length <= _didLayoutRange.location) {
        return NSNotFound;
    }
    if (willLayRange.location >= _didLayoutRange.location && willLayRange.location < _didLayoutRange.location + _didLayoutRange.length) {
        return willLayRange.location;
    }else{
        return willLayRange.location + willLayRange.length - 1;
    }
}

#pragma mark - add items
/**
 在可视Range范围内添加items
 
 @param visibleRange 可视范围索引
 */
- (void)addVisibleItemsInVisibleRange:(NSRange)visibleRange {
    for (NSInteger idx = visibleRange.location ; idx < visibleRange.location + visibleRange.length; ++idx) {
        DQpageIndexStoreState storeState = [self caculateIndexState:idx];
        id visibleItem;
        switch (storeState) {
            case DQpageIndexStoreStateVisible:
                break;
            case DQpageIndexStoreStatePrefect:{
                visibleItem =  self.prefetchIndexItems[@(idx)];
                self.visibleIndexItems[@(idx)] = visibleItem;
                [self addVisibleItem:visibleItem atIndex:idx];
                break;
            }
            case DQpageIndexStoreStateCache:{
                visibleItem = [self cacheItemForKey:@(idx)];
                self.visibleIndexItems[@(idx)] = visibleItem;
                [self addVisibleItem:visibleItem atIndex:idx];
                break;
            }
            default:{
                visibleItem = [_dataSource pageViewLayout:self itemForIndex:idx prefetching:NO];
                _visibleIndexItems[@(idx)] = visibleItem;
                [self addVisibleItem:visibleItem atIndex:idx];
                break;
            }
        }
        if (_autoMemoryCache && visibleItem) {
            [self cacheItem:visibleItem forKey:@(idx)];
        }
    }
}
/**
 在可视的index索引上添加item
 
 @param visibleItem 控制器
 @param index 索引
 */
- (void)addVisibleItem:(id)visibleItem atIndex:(NSInteger)index{
    if (!visibleItem) {
        NSAssert(visibleItem != nil, @"visibleView must not nil!");
        return;
    }
    UIView *view = [self viewForItem:visibleItem atIndex:index];
    if (view.superview && view.superview != _scrollView) {
        [view removeFromSuperview];
    }
    CGRect frame = [self frameForItemAtIndex:index];
    if (!CGRectEqualToRect(view.frame, frame)) {
        view.frame = frame;
    }
    if (!_prefetchItemWillAddToSuperView && view.superview) {
        return;
    }
    if (_prefetchItemWillAddToSuperView && view.superview) {
        UIViewController *viewController = [self viewControllerForItem:visibleItem atIndex:index];
        if (!viewController || viewController.parentViewController) {
            return;
        }
    }
    if (_dataSourceFlags.addVisibleItem) {
        [_dataSource pageViewLayout:self addVisibleItem:visibleItem atIndex:index];
    }else {
        NSAssert(NO, @"must implement datasource pageViewLayout:addVisibleItem:frame:atIndex:!");
    }
}

/**
 在可视范围外添加items

 @param visibleRange 可视范围索引
 */
- (void)addPrefetchItemsOutOfVisibleRange:(NSRange)visibleRange{
    if (_prefetchItemCount <= 0) {
        self.prefetchIndexItems = [_visibleIndexItems mutableCopy];
        return;
    }
    NSRange prefetchRange = prefetchRangeWithVisibleRange(visibleRange, _prefetchItemCount, _countOfpageItems);
    for (NSInteger index = prefetchRange.location; index < NSMaxRange(prefetchRange); ++index) {
        DQpageIndexStoreState storeState = [self caculateIndexState:index];
        id prefetchItem;
        switch (storeState) {
            case DQpageIndexStoreStateVisible:
                prefetchItem = _visibleIndexItems[@(index)];
                self.prefetchIndexItems[@(index)] = prefetchItem;
                break;
            case DQpageIndexStoreStatePrefect:
                break;
            case DQpageIndexStoreStateCache:{
                prefetchItem = [self cacheItemForKey:@(index)];
                self.prefetchIndexItems[@(index)] = prefetchItem;
                if (_dataSourceFlags.addVisibleItem) {
                    [_dataSource pageViewLayout:self addVisibleItem:prefetchItem atIndex:index];
                }else {
                    NSAssert(NO, @"must implement datasource pageViewLayout:addVisibleItem:frame:atIndex:!");
                }
                break;
            }
            default:{
                prefetchItem = [self prefetchInvisibleItemAtIndex:index];
                [self.prefetchIndexItems setObject:prefetchItem forKey:@(index)];
                break;
            }
        }
        if (_autoMemoryCache && prefetchItem) {
            [self cacheItem:prefetchItem forKey:@(index)];
        }
    }
}

/**
 dataSource-预取index位置可用的item
 dataSource-并把index位置的view添加到scrollView上
 
 @param index 索引
 @return 视图
 */
- (id)prefetchInvisibleItemAtIndex:(NSInteger)index {
    id prefetchItem = [_prefetchIndexItems objectForKey:@(index)];
    if (!prefetchItem) {
        prefetchItem = [_visibleIndexItems objectForKey:@(index)];
    }
    if (!prefetchItem) {
        prefetchItem = [self cacheItemForKey:@(index)];
    }
    if (!prefetchItem) {
        prefetchItem = [_dataSource pageViewLayout:self itemForIndex:index prefetching:YES];
        UIView *view = [self viewForItem:prefetchItem atIndex:index];
        CGRect frame = [self frameForItemAtIndex:index];
        if (!CGRectEqualToRect(view.frame, frame)) {
            view.frame = frame;
        }
        /** 预取得不不添加到视图上
        if (_prefetchItemWillAddToSuperView && view.superview != _scrollView) {
            if (_dataSourceFlags.addVisibleItem) {
                [_dataSource pageViewLayout:self addVisibleItem:prefetchItem atIndex:index];
            }else {
                NSAssert(NO, @"must implement datasource pageViewLayout:addVisibleItem:frame:atIndex:!");
            }
        }
         */
    }
    return prefetchItem;
}

#pragma mark - remove items

- (void)removeAllItems {
    [_scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UIViewController * pageController = [self viewController:_scrollView];
    [pageController.childViewControllers makeObjectsPerformSelector:@selector(removeFromParentViewController)];
//    _visibleIndexItems = nil;
//    _prefetchIndexItems = nil;
    [_visibleIndexItems removeAllObjects];
    [_prefetchIndexItems removeAllObjects];
    if (_reuseIdentifyItems) {
        [_reuseIdentifyItems removeAllObjects];
    }
}

- (UIViewController *)viewController:(UIView *)view{
    for (UIView* next = [view superview]; next; next = next.superview) {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}

- (void)removeVisibleItemsInVisibleRange:(NSRange)visibleRange {
    [_visibleIndexItems enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id item, BOOL * stop) {
        NSInteger index = [key integerValue];
        if (!NSLocationInRange(index, visibleRange)) {
            id invisibleItem = self.visibleIndexItems[key];
            if (_dataSourceFlags.removeInVisibleItem) {
                [_dataSource pageViewLayout:self removeInVisibleItem:invisibleItem atIndex:index];
            }else {
                NSAssert(NO, @"must implememt datasource pageViewLayout:removeInVisibleItem:atIndex:!");
            }
            [self.visibleIndexItems removeObjectForKey:key];
        }
    }];
}

- (void)removeUnVisibleItemsOutOfVisibleRange:(NSRange)visibleRange {
    NSRange prefetchRange = prefetchRangeWithVisibleRange(visibleRange, _prefetchItemCount, _countOfpageItems);
    for (NSNumber *idx in self.prefetchIndexItems.allKeys) {
        NSInteger index = [idx integerValue];
        if (!NSLocationInRange(index, prefetchRange)) {
            [self.prefetchIndexItems removeObjectForKey:idx];
            /** 暂不复用
            id invisibleItem = self.prefetchIndexItems[idx];
            [self.prefetchIndexItems removeObjectForKey:idx];
            NSObject *reuseItem = invisibleItem;
            if (_reuseIdentifyClassOrNib.count > 0 && reuseItem.dq_pageeuseIdentify.length > 0) {
                [self enqueueReusableItem:reuseItem prefetchRange:_prefetchRange atIndex:index];
            }else {
                [self cacheItem:invisibleItem forKey:@(index)];
            }
             */
        }
    }
}



- (UIViewController *)viewControllerForItem:(id)item atIndex:(NSInteger)index {
    UIViewController * viewController = (UIViewController *)item;
    return viewController;
//    if ([_dataSource respondsToSelector:@selector(pageViewLayout:viewControllerForItem:atIndex:)]) {
//        return [_dataSource pageViewLayout:self viewControllerForItem:item atIndex:index];
//    }
//    return nil;
}

#pragma mark - Delegate

#pragma mark - Notification

#pragma mark - getter setter

- (NSArray *)visibleItems {
    return _visibleIndexItems.allValues;
}

- (NSMutableDictionary *)visibleIndexItems{
    if (!_visibleIndexItems) {
        _visibleIndexItems = [[NSMutableDictionary alloc] init];
    }
    return _visibleIndexItems;
}

- (NSMutableDictionary *)prefetchIndexItems{
    if (!_prefetchIndexItems) {
        _prefetchIndexItems = [[NSMutableDictionary alloc] init];
    }
    return _prefetchIndexItems;
}

-(void)setPrefetchItemCount:(NSInteger)prefetchItemCount{
    _prefetchItemCount = prefetchItemCount;
}

- (NSMutableDictionary *)reuseIdentifyClassOrNib {
    if (!_reuseIdentifyClassOrNib) {
        _reuseIdentifyClassOrNib = [NSMutableDictionary dictionary];
    }
    return _reuseIdentifyClassOrNib;
}

-(NSMutableDictionary *)reuseIdentifyItems{
    if (!_reuseIdentifyItems) {
        _reuseIdentifyItems = [NSMutableDictionary dictionary];
    }
    return _reuseIdentifyItems;
}

- (void)setDataSource:(id<DQPageViewLayoutDataSource>)dataSource{
    _dataSource = dataSource;
    _dataSourceFlags.addVisibleItem = [dataSource respondsToSelector:@selector(pageViewLayout:addVisibleItem:atIndex:)];
    _dataSourceFlags.removeInVisibleItem = [dataSource respondsToSelector:@selector(pageViewLayout:removeInVisibleItem:atIndex:)];
}

- (void)setDelegate:(id<DQPageViewLayoutDelegate>)delegate{
    _delegate = delegate;
    _delegateFlags.transitionFromIndexToIndex = [delegate respondsToSelector:@selector(pageViewLayout:transitionFromIndex:toIndex:animated:)];
    _delegateFlags.transitionFromIndexToIndexProgress = [delegate respondsToSelector:@selector(pageViewLayout:transitionFromIndex:toIndex:progress:)];
    
    _delegateFlags.pageViewLayoutScrollLeftEndLoadMore = [delegate respondsToSelector:@selector(pageViewLayoutScrollLeftEndLoadMore:)];
    _delegateFlags.pageViewLayoutScrollRightEndLoadMore = [delegate respondsToSelector:@selector(pageViewLayoutScrollRightEndLoadMore:)];
    
    _delegateFlags.pageViewLayoutWillBeginScrollToView = [delegate respondsToSelector:@selector(pageViewLayoutWillBeginDragging:)];
    _delegateFlags.pageViewLayoutWillBeginScrollToView = [delegate respondsToSelector:@selector(pageViewLayoutDidEndDragging:willDecelerate:)];
    
    _delegateFlags.pageViewLayoutWillBeginScrollToView = [delegate respondsToSelector:@selector(pageViewLayoutWillBeginDragging:)];
    _delegateFlags.pageViewLayoutWillBeginScrollToView = [delegate respondsToSelector:@selector(pageViewLayoutWillBeginDecelerating:)];
    _delegateFlags.pageViewLayoutWillBeginScrollToView = [delegate respondsToSelector:@selector(pageViewLayoutDidEndDecelerating:)];
    _delegateFlags.pageViewLayoutWillBeginScrollToView = [delegate respondsToSelector:@selector(pageViewLayoutDidEndScrollingAnimation:)];

}

-(void)setFirstScrollToIndex:(NSInteger)firstScrollToIndex{
    _firstScrollToIndex = firstScrollToIndex;
}

#pragma mark - Lazy Loading

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!scrollView.superview) {
        return;
    }
    
    CGFloat offsetX = scrollView.contentOffset.x;
    DQpageScrollingDirection direction = [self caculateScrollViewDraggingDirection:_preOffsetX currentOffsetX:offsetX];

    //两个滑动的delegate方法
    if ([self progressCaculateEnable]) {
        [self caculateIndexByProgressWithOffsetX:offsetX direction:direction];
    }
    BOOL indexChange = [self caculateIndexWithOffsetX:offsetX direction:direction];
    
    if ([self preLayoutChildViewEnable:direction] && _needLayoutChildItems) {
        [self layoutChildItems];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
//    NSLog(@"1.scrollViewWillBeginDragging");
    _preOffsetX = scrollView.contentOffset.x;
    if (_delegateFlags.pageViewLayoutWillBeginDragging) {
        [_delegate pageViewLayoutWillBeginDragging:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//    NSLog(@"2.scrollViewDidEndDragging");

    if (_delegateFlags.pageViewLayoutDidEndDragging) {
         [_delegate pageViewLayoutDidEndDragging:self willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
//    NSLog(@"3.scrollViewWillBeginDecelerating");
    
    CGFloat offsetX = scrollView.contentOffset.x;
    DQpageScrollingDirection direction = [self caculateScrollViewDraggingDirection:_preOffsetX currentOffsetX:offsetX];
    [self scrollViewToBothEndAndMore:direction];
    
    if (_delegateFlags.pageViewLayoutWillBeginDecelerating) {
        [_delegate pageViewLayoutWillBeginDecelerating:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    NSLog(@"4.scrollViewDidEndDecelerating");
    
    if (_scrollLeftEndMore && _delegateFlags.pageViewLayoutScrollLeftEndLoadMore) {
        [_delegate pageViewLayoutScrollLeftEndLoadMore:self];
        _scrollLeftEndMore = NO;
    }
    
    if (_scrollRightEndMore && _delegateFlags.pageViewLayoutScrollRightEndLoadMore) {
        [_delegate pageViewLayoutScrollRightEndLoadMore:self];
        _scrollRightEndMore = NO;
    }
    
    if (_delegateFlags.pageViewLayoutDidEndDecelerating) {
        [_delegate pageViewLayoutDidEndDecelerating:self];
    }
}


- (void)scrollViewWillScrollToView:(UIScrollView *)scrollView animate:(BOOL)animate {
    _preOffsetX = scrollView.contentOffset.x;
    _isTapScrollMoved = YES;
    _scrollAnimated = animate;
    if ([_delegate respondsToSelector:@selector(pageViewLayoutWillBeginScrollToView:animate:)]) {
        [_delegate pageViewLayoutWillBeginScrollToView:self animate:animate];
    }
}

- (void)scrollViewDidScrollToView:(UIScrollView *)scrollView animate:(BOOL)animate {
    if ([_delegate respondsToSelector:@selector(pageViewLayoutDidEndScrollToView:animate:)]) {
        [_delegate pageViewLayoutDidEndScrollToView:self animate:animate];
    }
}


#pragma mark - register && dequeue

- (void)registerClass:(Class)Class forItemWithReuseIdentifier:(NSString *)identifier {
    [self.reuseIdentifyClassOrNib setObject:Class forKey:identifier];
}

- (void)registerNib:(UINib *)nib forItemWithReuseIdentifier:(NSString *)identifier {
    [self.reuseIdentifyClassOrNib setObject:nib forKey:identifier];
}
//出栈
- (id)dequeueReusableItemWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    NSAssert(_reuseIdentifyClassOrNib.count != 0, @"you don't register any identifiers!");
    NSObject *item = [self.reuseIdentifyItems objectForKey:identifier];
    if (item) {
        [self.reuseIdentifyItems removeObjectForKey:identifier];
        return item;
    }
    id itemClassOrNib = [self.reuseIdentifyClassOrNib objectForKey:identifier];
    if (!itemClassOrNib) {
        NSString *error = [NSString stringWithFormat:@"you don't register this identifier->%@",identifier];
        NSAssert(NO, error);
        NSLog(@"%@", error);
        return nil;
    }
    
    if (class_isMetaClass(object_getClass(itemClassOrNib))) {
        // is class
        item = [[((Class)itemClassOrNib) alloc]init];
    }else if ([itemClassOrNib isKindOfClass:[UINib class]]) {
        // is nib
        item =[((UINib *)itemClassOrNib)instantiateWithOwner:nil options:nil].firstObject;
    }
    if (!item){
        NSString *error = [NSString stringWithFormat:@"you register identifier->%@ is not class or nib!",identifier];
        NSAssert(NO, error);
        NSLog(@"%@", error);
        return nil;
    }
    [item setDq_pageeuseIdentify:identifier];
//    UIView *view = [_dataSource pageViewLayout:self viewForItem:item atIndex:index];
//    view.frame = [self frameForItemAtIndex:index];
    return item;
}
//入栈
- (void)enqueueReusableItem:(NSObject *)reuseItem prefetchRange:(NSRange)prefetchRange atIndex:(NSInteger)index{
    if (reuseItem.dq_pageeuseIdentify.length == 0 || NSLocationInRange(index, prefetchRange)) {
        return;
    }
    [self.reuseIdentifyItems setObject:reuseItem forKey:reuseItem.dq_pageeuseIdentify];
}

#pragma mark - Observer

- (void)addScrollViewObservers{
    [self addObserver:self forKeyPath:kScrollViewFrameObserverKey options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:kScrollViewFrameObserverKey]) {
        CGRect newFrame = [[change objectForKey:NSKeyValueChangeNewKey]CGRectValue];
        CGRect oldFrame = [[change objectForKey:NSKeyValueChangeOldKey]CGRectValue];
        BOOL needLayoutContent = !CGRectEqualToRect(newFrame, oldFrame);
        if (needLayoutContent) {
            [self setNeedLayout];
        }
    }
}

- (void)removeScrollViewObservers {
    [self removeObserver:self forKeyPath:kScrollViewFrameObserverKey context:nil];
}

#pragma mark - memoryCache

- (void)cacheItem:(id)item forKey:(NSNumber *)key {
    if (_autoMemoryCache && key) {
        UIView *cacheItem = [self.memoryCache objectForKey:key];
        if (cacheItem && cacheItem == item) {
            return;
        }
        [self.memoryCache setObject:item forKey:key];
    }
}

- (id)cacheItemForKey:(NSNumber *)key {
    if (_autoMemoryCache && _memoryCache && key) {
        return [_memoryCache objectForKey:key];
    }
    return nil;
}

- (void)clearMemoryCache {
    if (_autoMemoryCache && _memoryCache) {
        [_memoryCache removeAllObjects];
    }
}

@end












