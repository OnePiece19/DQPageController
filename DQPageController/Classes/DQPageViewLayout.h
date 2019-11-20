//
//  DQPageViewLayout.h
//  NWN_Component
//
//  Created by HX on 2018/12/28.
//  Copyright © 2018 offcn.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DQPageViewLayout;

@interface NSObject (DQpageReuseIdentify)
// resueId
@property (nonatomic, strong, readonly, nullable) NSString * dq_pageReuseIdentify;

@end


@protocol DQPageViewLayoutDataSource <NSObject>

@required

- (NSInteger)numberOfItemsInpageViewLayout;

- (id _Nullable )pageViewLayout:(DQPageViewLayout *_Nullable)pageViewLayout itemForIndex:(NSInteger)index prefetching:(BOOL)prefetching;

@optional

NS_ASSUME_NONNULL_BEGIN

- (UIView *_Nullable)pageViewLayout:(DQPageViewLayout *_Nonnull)pageViewLayout viewForItem:(id)item atIndex:(NSInteger)index;

- (void)pageViewLayout:(DQPageViewLayout *)pageViewLayout addVisibleItem:(id)item atIndex:(NSInteger)index;

- (void)pageViewLayout:(DQPageViewLayout *)pageViewLayout removeInVisibleItem:(id)item atIndex:(NSInteger)index;

NS_ASSUME_NONNULL_END

@end


@protocol DQPageViewLayoutDelegate <NSObject>

NS_ASSUME_NONNULL_BEGIN

- (void)pageViewLayout:(DQPageViewLayout *)pageViewLayout transitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex animated:(BOOL)animated;

- (void)pageViewLayout:(DQPageViewLayout *)pageViewLayout transitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress;

- (void)pageViewLayoutScrollLeftEndLoadMore:(DQPageViewLayout *)pageViewLayout;

- (void)pageViewLayoutScrollRightEndLoadMore:(DQPageViewLayout *)pageViewLayout;

/** ScrollViewDelegate */
- (void)pageViewLayoutWillBeginScrollToView:(DQPageViewLayout *)pageViewLayout animate:(BOOL)animate;

- (void)pageViewLayoutDidEndScrollToView:(DQPageViewLayout *)pageViewLayout animate:(BOOL)animate;

- (void)pageViewLayoutWillBeginDragging:(DQPageViewLayout *)pageViewLayout;

- (void)pageViewLayoutDidEndDragging:(DQPageViewLayout *)pageViewLayout willDecelerate:(BOOL)decelerate;

- (void)pageViewLayoutWillBeginDecelerating:(DQPageViewLayout *)pageViewLayout;

- (void)pageViewLayoutDidEndDecelerating:(DQPageViewLayout *)pageViewLayout;

- (void)pageViewLayoutDidEndScrollingAnimation:(DQPageViewLayout *)pageViewLayout;

NS_ASSUME_NONNULL_END

@end


NS_ASSUME_NONNULL_BEGIN

@interface DQPageViewLayout<__covariant ItemType> : NSObject

@property (nonatomic, weak, nullable) id<DQPageViewLayoutDataSource> dataSource;
@property (nonatomic, weak, nullable) id<DQPageViewLayoutDelegate> delegate;

@property (nonatomic, strong, readonly) UIScrollView * scrollView;

@property (nonatomic, assign, readonly) NSInteger countOfpageItems;
@property (nonatomic, assign, readonly) NSInteger curIndex;  //default -1
@property (nonatomic, assign) NSInteger firstScrollToIndex;

@property (nonatomic, assign) NSInteger prefetchItemCount; // contain left and right
@property (nonatomic, assign) BOOL prefetchItemWillAddToSuperView;
@property (nonatomic, assign, readonly) NSRange prefetchRange;
@property (nonatomic, assign, readonly) NSRange visibleRange;

@property (nonatomic, assign) BOOL adjustScrollViewInset;

@property (nonatomic, strong, nullable, readonly) NSArray<NSNumber *> * visibleIndexs;
@property (nonatomic, strong, nullable, readonly) NSArray<ItemType> * visibleItems;

@property (nonatomic, strong, readonly) NSCache<NSNumber *, ItemType> *memoryCache;
@property (nonatomic, assign) BOOL autoMemoryCache;

@property (nonatomic, assign) CGFloat changeIndexWhenScrollProgress;

@property (nonatomic, assign) BOOL progressAnimateEnabel;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithScrollView:(UIScrollView *)scrollView NS_DESIGNATED_INITIALIZER;

- (UIViewController *_Nullable)viewControllerForItem:(id)item atIndex:(NSInteger)index;

- (UIView *)viewForItem:(ItemType)item atIndex:(NSInteger)index;

- (ItemType _Nullable)itemForIndex:(NSInteger)index;

- (CGRect)frameForItemAtIndex:(NSInteger)index;

- (void)scrollToItemAtIndex:(NSInteger)index animate:(BOOL)animate;

- (void)scrollToNextPage:(BOOL)animate;

/** register && dequeue's usage like tableView */
- (void)registerClass:(Class)Class forItemWithReuseIdentifier:(NSString *)identifier;

- (void)registerNib:(UINib *)nib forItemWithReuseIdentifier:(NSString *)identifier;

- (ItemType)dequeueReusableItemWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

/**
 * update data and layout，the same to relaodData,but don't reset propertys(curIndex,visibleDatas,prefechDatas)
 */
- (void)updateData;

/**
 * reload data and reset propertys
 */
- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
