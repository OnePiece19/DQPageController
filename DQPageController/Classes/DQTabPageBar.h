//
//  DQTabPageBar.h
//  WXQuestion
//
//  Created by HX on 2019/3/18.
//  Copyright © 2019 中公网校. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQTabPageBarLayout.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DQTabPageBarDataSource <NSObject>

- (NSInteger)numberOfItemsInPageTabBar;

- (UICollectionViewCell<DQTabPageBarCellProtocol> *)pageTabBar:(DQTabPageBar *)pageTabBar cellForItemAtIndex:(NSInteger)index;

@end

@protocol DQTabPageBarDelegate <NSObject>

@optional

// configure layout
- (void)pageTabBar:(DQTabPageBar *)pageTabBar configureLayout:(DQTabPageBarLayout *)layout;

// if cell wdith is not variable,you can set layout.cellWidth. otherwise ,you can implement this return cell width. cell width not contain cell edge
- (CGFloat)pageTabBar:(DQTabPageBar *)pageTabBar widthForItemAtIndex:(NSInteger)index;

// did select cell item
- (void)pageTabBar:(DQTabPageBar *)pageTabBar didSelectItemAtIndex:(NSInteger)index;

// transition frome cell to cell with animated
- (void)pageTabBar:(DQTabPageBar *)pageTabBar transitionFromeCell:(UICollectionViewCell<DQTabPageBarCellProtocol> * _Nullable)fromCell toCell:(UICollectionViewCell<DQTabPageBarCellProtocol> * _Nullable)toCell animated:(BOOL)animated;

// transition frome cell to cell with progress
- (void)pageTabBar:(DQTabPageBar *)pageTabBar transitionFromeCell:(UICollectionViewCell<DQTabPageBarCellProtocol> * _Nullable)fromCell toCell:(UICollectionViewCell<DQTabPageBarCellProtocol> * _Nullable)toCell progress:(CGFloat)progress;

@end




@interface DQTabPageBar : UIView

@property (nonatomic, strong) DQTabPageBarLayout *layout;

@property (nonatomic, weak, readonly) UICollectionView *collectionView;

@property (nonatomic, strong) UIView *progressView;

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) UIView *bottomLineView;

@property (nonatomic, weak, nullable) id<DQTabPageBarDataSource> dataSource;

@property (nonatomic, weak, nullable) id<DQTabPageBarDelegate> delegate;

@property (nonatomic, assign) BOOL autoScrollItemToCenter;

@property (nonatomic, assign, readonly) NSInteger countOfItems;

@property (nonatomic, assign, readonly) NSInteger curIndex;

@property (nonatomic, assign) UIEdgeInsets contentInset;

- (void)reloadData;

- (void)scrollToItemFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex animate:(BOOL)animate;

- (void)scrollToItemFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress;

- (void)scrollToItemAtIndex:(NSInteger)index atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;


- (CGFloat)cellWidthForTitle:(NSString * _Nullable)title;

- (CGRect)cellFrameWithIndex:(NSInteger)index;

- (nullable UICollectionViewCell<DQTabPageBarCellProtocol> *)cellForIndex:(NSInteger)index;

- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier;

- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;

- (__kindof UICollectionViewCell<DQTabPageBarCellProtocol> *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;


@end

NS_ASSUME_NONNULL_END
