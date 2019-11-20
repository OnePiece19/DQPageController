//
//  DQTabPageBarLayout.m
//  WXQuestion
//
//  Created by HX on 2019/3/18.
//  Copyright © 2019 中公网校. All rights reserved.
//

#import "DQTabPageBarLayout.h"
#import "DQTabPageBar.h"

@interface DQTabPageBarLayout()

@property (nonatomic, weak) DQTabPageBar *pageTabBar;

@property (nonatomic, assign) CGFloat selectFontScale;

@end

#define kUnderLineViewHeight 2

@implementation DQTabPageBarLayout

- (instancetype)initWithPagerTabBar:(DQTabPageBar *)pageTabBar {
    if (self = [super init]) {
        _pageTabBar = pageTabBar;
        [self configurePropertys];
        self.barStyle = DQPageBarStyleProgressElasticView;
    }
    return self;
}

- (void)configurePropertys {
    _cellSpacing = 0;
    _cellEdging = 15;
    _cellWidth = 0;
    
    
    _progressHorEdging = 0;
    _progressVerEdging = 0;
    _progressWidth = 0;
    _animateDuration = 0.25;
    
    
    _normalTextFont = [UIFont fontWithName:@"PingFangSC-Regular" size:15.0f];
    _selectedTextFont = [UIFont fontWithName:@"PingFangSC-Medium" size:15.0f];
    _normalTextColor = [UIColor colorWithRed:125.0f/255.0f green:130.0f/255.0f blue:154.0f/255.0f
                                       alpha:1.0f];
    _selectedTextColor = [UIColor colorWithRed:42.0f/255.0f green:46.0f/255.0f blue:61.0f/255.0f
                                         alpha:1.0f];
    _selectFontScale = self.normalTextFont.pointSize/(self.selectedTextFont ? self.selectedTextFont.pointSize:self.normalTextFont.pointSize);
    _textColorProgressEnable = YES;
}

#pragma mark - geter setter

- (void)setProgressRadius:(CGFloat)progressRadius {
    _progressRadius = progressRadius;
    _pageTabBar.progressView.layer.cornerRadius = progressRadius;
}

- (void)setProgressBorderWidth:(CGFloat)progressBorderWidth {
    _progressBorderWidth = progressBorderWidth;
    _pageTabBar.progressView.layer.borderWidth = progressBorderWidth;
}

- (void)setProgressBorderColor:(UIColor *)progressBorderColor {
    _progressBorderColor = progressBorderColor;
    if (!_progressColor) {
        _pageTabBar.progressView.backgroundColor = [UIColor clearColor];
    }
    _pageTabBar.progressView.layer.borderColor = progressBorderColor.CGColor;
}

- (void)setProgressColor:(UIColor *)progressColor {
    _progressColor = progressColor;
    _pageTabBar.progressView.backgroundColor = progressColor;
}

- (void)setProgressHeight:(CGFloat)progressHeight {
    _progressHeight = progressHeight;
    CGRect frame = _pageTabBar.progressView.frame;
    CGFloat height = CGRectGetHeight(_pageTabBar.collectionView.frame);
    frame.origin.y = _barStyle == DQPageBarStyleCoverView ? (height - _progressHeight)/2:(height - _progressHeight - _progressVerEdging);
    frame.size.height = progressHeight;
    _pageTabBar.progressView.frame = frame;
}

- (UIEdgeInsets)sectionInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_sectionInset, UIEdgeInsetsZero) || _barStyle != DQPageBarStyleCoverView) {
        return _sectionInset;
    }
    if (_barStyle == DQPageBarStyleCoverView && _adjustContentCellsCenter) {
        return _sectionInset;
    }
    CGFloat horEdging = -_progressHorEdging+_cellSpacing;
    return UIEdgeInsetsMake(0, horEdging, 0, horEdging);
}

- (void)setAdjustContentCellsCenter:(BOOL)adjustContentCellsCenter {
    BOOL change = _adjustContentCellsCenter != adjustContentCellsCenter;
    _adjustContentCellsCenter = adjustContentCellsCenter;
    if (change && _pageTabBar.superview) {
        [_pageTabBar setNeedsLayout];
    }
}

- (void)setBarStyle:(DQPageBarStyle)barStyle
{
    if (barStyle == _barStyle) {
        return;
    }
    if (_barStyle == DQPageBarStyleCoverView) {
        self.progressBorderWidth = 0;
        self.progressBorderColor = nil;
    }
    _barStyle = barStyle;
    switch (barStyle) {
        case DQPageBarStyleProgressView:
            self.progressWidth = 0;
            self.progressHorEdging = 6;
            self.progressVerEdging = 0;
            self.progressHeight = kUnderLineViewHeight;
            break;
        case DQPageBarStyleProgressBounceView:
        case DQPageBarStyleProgressElasticView:
            self.progressWidth = 0;
            self.progressVerEdging = 7;
            self.progressHorEdging = 15;
            self.progressHeight = kUnderLineViewHeight;
            break;
        case DQPageBarStyleCoverView:
            self.progressWidth = 0;
            self.progressHorEdging = -self.progressHeight/4;
            self.progressVerEdging = 3;
            break;
        default:
            break;
    }
    _pageTabBar.progressView.hidden = barStyle == DQPageBarStyleNoneView;
    if (barStyle == DQPageBarStyleCoverView) {
        _progressRadius = 0;
        _pageTabBar.progressView.layer.zPosition = -1;
        [_pageTabBar.progressView removeFromSuperview];
        [_pageTabBar.collectionView insertSubview: _pageTabBar.progressView atIndex:0];
    }else {
        self.progressRadius = _progressHeight/2;
        if (_pageTabBar.progressView.layer.zPosition == -1) {
            _pageTabBar.progressView.layer.zPosition = 0;
            [_pageTabBar.progressView removeFromSuperview];
            [_pageTabBar.collectionView addSubview:_pageTabBar.progressView];
        }
    }
    
}

#pragma mark - public

- (void)layoutIfNeed {
    UICollectionViewFlowLayout *collectionLayout = (UICollectionViewFlowLayout *)_pageTabBar.collectionView.collectionViewLayout;
    collectionLayout.minimumLineSpacing = _cellSpacing;
    collectionLayout.minimumInteritemSpacing = _cellSpacing;
    _selectFontScale = self.normalTextFont.pointSize/(self.selectedTextFont ? self.selectedTextFont.pointSize:self.normalTextFont.pointSize);
    collectionLayout.sectionInset = _sectionInset;
}

- (void)invalidateLayout {
    [_pageTabBar.collectionView.collectionViewLayout invalidateLayout];
}

- (void)adjustContentCellsCenterInBar {
    if (!_adjustContentCellsCenter || !_pageTabBar.superview) {
        return;
    }
    CGRect frame = self.pagerTabBar.collectionView.frame;
    if (CGRectIsEmpty(frame)) {
        return;
    }
    
    UICollectionViewFlowLayout *collectionLayout = (UICollectionViewFlowLayout *)_pageTabBar.collectionView.collectionViewLayout;
    CGSize contentSize = collectionLayout.collectionViewContentSize;
    NSArray *layoutAttribulte = [collectionLayout layoutAttributesForElementsInRect:CGRectMake(0, 0, MAX(contentSize.width, CGRectGetWidth(frame)), MAX(contentSize.height,CGRectGetHeight(frame)))];
    if (layoutAttribulte.count == 0) {
        return;
    }
    
    UICollectionViewLayoutAttributes *firstAttribute = layoutAttribulte.firstObject;
    UICollectionViewLayoutAttributes *lastAttribute = layoutAttribulte.lastObject;
    CGFloat left = CGRectGetMinX(firstAttribute.frame);
    CGFloat right = CGRectGetMaxX(lastAttribute.frame);
    if (right - left > CGRectGetWidth(self.pagerTabBar.frame)) {
        return;
    }
    CGFloat sapce = (CGRectGetWidth(self.pagerTabBar.frame) - (right - left))/2;
    _sectionInset = UIEdgeInsetsMake(_sectionInset.top, sapce, _sectionInset.bottom, sapce);
    collectionLayout.sectionInset = _sectionInset;
}

- (CGRect)cellFrameWithIndex:(NSInteger)index {
    return [_pageTabBar cellFrameWithIndex:index];
}

#pragma mark - cell

- (void)transitionFromCell:(UICollectionViewCell<DQTabPageBarCellProtocol> *)fromCell toCell:(UICollectionViewCell<DQTabPageBarCellProtocol> *)toCell animate:(BOOL)animate {
    if (_pageTabBar.countOfItems == 0) {
        return;
    }
    // 其实不会循环引用，保险加上__weak
    __weak typeof(self) weakSelf = self;
    void (^animateBlock)(void) = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (fromCell) {
            fromCell.titleLabel.font = strongSelf.normalTextFont;
            fromCell.titleLabel.textColor = strongSelf.normalTextColor;
            fromCell.transform = CGAffineTransformMakeScale(strongSelf.selectFontScale, strongSelf.selectFontScale);
        }
        if (toCell) {
            toCell.titleLabel.font = strongSelf.selectedTextFont;
            toCell.titleLabel.textColor = strongSelf.selectedTextColor ? strongSelf.selectedTextColor : strongSelf.normalTextColor;
            toCell.transform = CGAffineTransformIdentity;
        }
    };
    if (animate) {
        [UIView animateWithDuration:_animateDuration animations:^{
            animateBlock();
        }];
    }else{
        animateBlock();
    }
}

- (void)transitionFromCell:(UICollectionViewCell<DQTabPageBarCellProtocol> *)fromCell toCell:(UICollectionViewCell<DQTabPageBarCellProtocol> *)toCell progress:(CGFloat)progress {
    if (_pageTabBar.countOfItems == 0 || !_textColorProgressEnable) {
        return;
    }
    CGFloat currentTransform = (1.0 - _selectFontScale)*progress;
    fromCell.transform = CGAffineTransformMakeScale(1.0-currentTransform, 1.0-currentTransform);
    toCell.transform = CGAffineTransformMakeScale(_selectFontScale+currentTransform, _selectFontScale+currentTransform);
    
    if (_normalTextColor == _selectedTextColor || !_selectedTextColor) {
        return;
    }
    
    CGFloat narR=0,narG=0,narB=0,narA=1;
    [_normalTextColor getRed:&narR green:&narG blue:&narB alpha:&narA];
    CGFloat selR=0,selG=0,selB=0,selA=1;
    [_selectedTextColor getRed:&selR green:&selG blue:&selB alpha:&selA];
    CGFloat detalR = narR - selR ,detalG = narG - selG,detalB = narB - selB,detalA = narA - selA;
    
    fromCell.titleLabel.textColor = [UIColor colorWithRed:selR+detalR*progress green:selG+detalG*progress blue:selB+detalB*progress alpha:selA+detalA*progress];
    toCell.titleLabel.textColor = [UIColor colorWithRed:narR-detalR*progress green:narG-detalG*progress blue:narB-detalB*progress alpha:narA-detalA*progress];
}

#pragma mark - progress View

// set up progress view frame
- (void)setUnderLineFrameWithIndex:(NSInteger)index animated:(BOOL)animated
{
    UIView *progressView = _pageTabBar.progressView;
    if (progressView.isHidden || _pageTabBar.countOfItems == 0) {
        return;
    }
    
    CGRect cellFrame = [self cellFrameWithIndex:index];
    CGFloat progressHorEdging = _progressWidth > 0 ? (cellFrame.size.width - _progressWidth)/2 : _progressHorEdging;
    
    CGFloat progressX = cellFrame.origin.x+progressHorEdging;
    
    CGFloat progressY = _barStyle == DQPageBarStyleCoverView ? (cellFrame.size.height - _progressHeight)/2:(cellFrame.size.height - _progressHeight - _progressVerEdging);
    
    CGFloat width = cellFrame.size.width-2*progressHorEdging;
    
    if (animated) {
        [UIView animateWithDuration:_animateDuration animations:^{
            progressView.frame = CGRectMake(progressX, progressY, width, self.progressHeight);
        }];
    }else {
        progressView.frame = CGRectMake(progressX, progressY, width, _progressHeight);
    }
}

- (void)setUnderLineFrameWithfromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress
{
    UIView *progressView = _pageTabBar.progressView;
    if (progressView.isHidden || _pageTabBar.countOfItems == 0) {
        return;
    }
    
    CGRect fromCellFrame = [self cellFrameWithIndex:fromIndex];
    CGRect toCellFrame = [self cellFrameWithIndex:toIndex];
    
    CGFloat progressFromEdging = _progressWidth > 0 ? (fromCellFrame.size.width - _progressWidth)/2 : _progressHorEdging;
    CGFloat progressToEdging = _progressWidth > 0 ? (toCellFrame.size.width - _progressWidth)/2 : _progressHorEdging;
    CGFloat progressY = _barStyle == DQPageBarStyleCoverView ? (toCellFrame.size.height - _progressHeight)/2:(toCellFrame.size.height - _progressHeight - _progressVerEdging);
    CGFloat progressX = 0, width = 0;
    
    if (_barStyle == DQPageBarStyleProgressBounceView) {
        if (fromCellFrame.origin.x < toCellFrame.origin.x) {
            if (progress <= 0.5) {
                progressX = fromCellFrame.origin.x + progressFromEdging;
                width = (toCellFrame.size.width-progressToEdging+progressFromEdging+_cellSpacing)*2*progress + fromCellFrame.size.width-2*progressFromEdging;
            }else {
                progressX = fromCellFrame.origin.x + progressFromEdging + (fromCellFrame.size.width-progressFromEdging+progressToEdging+_cellSpacing)*(progress-0.5)*2;
                width = CGRectGetMaxX(toCellFrame)-progressToEdging - progressX;
            }
        }else {
            if (progress <= 0.5) {
                progressX = fromCellFrame.origin.x + progressFromEdging - (toCellFrame.size.width-progressToEdging+progressFromEdging+_cellSpacing)*2*progress;
                width = CGRectGetMaxX(fromCellFrame) - progressFromEdging - progressX;
            }else {
                progressX = toCellFrame.origin.x + progressToEdging;
                width = (fromCellFrame.size.width-progressFromEdging+progressToEdging + _cellSpacing)*(1-progress)*2 + toCellFrame.size.width - 2*progressToEdging;
            }
        }
    }else if (_barStyle == DQPageBarStyleProgressElasticView) {
        if (fromCellFrame.origin.x < toCellFrame.origin.x) {
            if (progress <= 0.5) {
                progressX = fromCellFrame.origin.x + progressFromEdging + (fromCellFrame.size.width-2*progressFromEdging)*progress;
                width = (toCellFrame.size.width-progressToEdging+progressFromEdging+_cellSpacing)*2*progress - (toCellFrame.size.width-2*progressToEdging)*progress + fromCellFrame.size.width-2*progressFromEdging-(fromCellFrame.size.width-2*progressFromEdging)*progress;
            }else {
                progressX = fromCellFrame.origin.x + progressFromEdging + (fromCellFrame.size.width-2*progressFromEdging)*0.5 + (fromCellFrame.size.width-progressFromEdging - (fromCellFrame.size.width-2*progressFromEdging)*0.5 +progressToEdging+_cellSpacing)*(progress-0.5)*2;
                width = CGRectGetMaxX(toCellFrame)-progressToEdging - progressX - (toCellFrame.size.width-2*progressToEdging)*(1-progress);
            }
        }else {
            if (progress <= 0.5) {
                progressX = fromCellFrame.origin.x + progressFromEdging - (toCellFrame.size.width-(toCellFrame.size.width-2*progressToEdging)/2-progressToEdging+progressFromEdging+_cellSpacing)*2*progress;
                width = CGRectGetMaxX(fromCellFrame) - (fromCellFrame.size.width-2*progressFromEdging)*progress - progressFromEdging - progressX;
            }else {
                progressX = toCellFrame.origin.x + progressToEdging+(toCellFrame.size.width-2*progressToEdging)*(1-progress);
                width = (fromCellFrame.size.width-progressFromEdging+progressToEdging-(fromCellFrame.size.width-2*progressFromEdging)/2 + _cellSpacing)*(1-progress)*2 + toCellFrame.size.width - 2*progressToEdging - (toCellFrame.size.width-2*progressToEdging)*(1-progress);
            }
        }
    }else {
        progressX = (toCellFrame.origin.x+progressToEdging-(fromCellFrame.origin.x+progressFromEdging))*progress+fromCellFrame.origin.x+progressFromEdging;
        width = (toCellFrame.size.width-2*progressToEdging)*progress + (fromCellFrame.size.width-2*progressFromEdging)*(1-progress);
    }
    
    progressView.frame = CGRectMake(progressX,progressY, width, _progressHeight);
}

- (void)layoutSubViews {
    if (CGRectIsEmpty(_pageTabBar.frame)) {
        return;
    }
    if (_barStyle == DQPageBarStyleCoverView) {
        self.progressHeight = CGRectGetHeight(_pageTabBar.collectionView.frame) -self.progressVerEdging*2;
        self.progressRadius = _progressRadius > 0 ? _progressRadius : self.progressHeight/2;
    }
    [self setUnderLineFrameWithIndex:_pageTabBar.curIndex animated:NO];
}

@end
