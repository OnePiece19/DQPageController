//
//  DQTabPageBarLayout.h
//  WXQuestion
//
//  Created by HX on 2019/3/18.
//  Copyright © 2019 中公网校. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DQTabPageBarCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DQPageBarStyle) {
    DQPageBarStyleNoneView,
    DQPageBarStyleProgressView,
    DQPageBarStyleProgressBounceView,
    DQPageBarStyleProgressElasticView,
    DQPageBarStyleCoverView,
};

@class DQTabPageBar;

@interface DQTabPageBarLayout : NSObject

@property (nonatomic, weak, readonly) DQTabPageBar *pagerTabBar;

@property (nonatomic, assign) DQPageBarStyle barStyle; // default TYPagerBarStyleProgressElasticView



@property (nonatomic, assign) UIEdgeInsets sectionInset;


@property (nonatomic, assign) CGFloat progressHeight;   // default 2
@property (nonatomic, assign) CGFloat progressWidth; //if > 0 progress width is equal,else progress width is cell width
@property (nonatomic, strong, nullable) UIColor *progressColor;

@property (nonatomic, assign) CGFloat progressRadius;   // height/2
@property (nonatomic, assign) CGFloat progressBorderWidth;
@property (nonatomic, strong, nullable) UIColor *progressBorderColor;

@property (nonatomic, assign) CGFloat progressHorEdging; // default 6, if < 0 width + edge ,if >0 width - edge
@property (nonatomic, assign) CGFloat progressVerEdging; // default 0, cover style is 3.

// cell frame
@property (nonatomic, assign) CGFloat cellWidth; // default 0, if > 0 cells width is equal,else if = 0 cell will call delegate
@property (nonatomic, assign) CGFloat cellSpacing; // default 2,cell space
@property (nonatomic, assign) CGFloat cellEdging;  // default 0,cell left right edge
@property (nonatomic, assign) BOOL adjustContentCellsCenter;// default NO, cells center if contentSize < bar's width ,will set sectionInset

// TYTabPagerBarCellProtocol -> cell's label
@property (nonatomic, strong) UIFont *normalTextFont;       // default 15
@property (nonatomic, strong) UIFont *selectedTextFont;     // default 17
@property (nonatomic, strong) UIColor *normalTextColor;     // default 51.51.51
@property (nonatomic, strong) UIColor *selectedTextColor;   // default white
@property (nonatomic, assign) CGFloat selectFontScale;      // default normalTextFontSize/selectedTextFontSize, you can set 1.0
@property (nonatomic, assign) BOOL textColorProgressEnable; // default YES

//   animate duration
@property (nonatomic, assign) CGFloat animateDuration;  // default 0.3

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithPagerTabBar:(DQTabPageBar *)pagerTabBar NS_DESIGNATED_INITIALIZER;

- (void)layoutIfNeed;

- (void)invalidateLayout;

- (void)layoutSubViews;

- (void)adjustContentCellsCenterInBar;

// override
- (void)transitionFromCell:(UICollectionViewCell<DQTabPageBarCellProtocol> *_Nullable)fromCell toCell:(UICollectionViewCell<DQTabPageBarCellProtocol> *_Nullable)toCell animate:(BOOL)animate;

- (void)transitionFromCell:(UICollectionViewCell<DQTabPageBarCellProtocol> *_Nullable)fromCell toCell:(UICollectionViewCell<DQTabPageBarCellProtocol> *_Nullable)toCell progress:(CGFloat)progress;

- (void)setUnderLineFrameWithIndex:(NSInteger)index animated:(BOOL)animated;

- (void)setUnderLineFrameWithfromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_END
