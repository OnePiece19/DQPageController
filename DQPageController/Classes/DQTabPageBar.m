//
//  DQTabPageBar.m
//  WXQuestion
//
//  Created by HX on 2019/3/18.
//  Copyright © 2019 中公网校. All rights reserved.
//

#import "DQTabPageBar.h"

@interface DQTabPageBar()<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>
{
    struct {
        unsigned int transitionFromeCellAnimated :1;
        unsigned int transitionFromeCellProgress :1;
        unsigned int didSelectItemAtIndex :1;
        unsigned int widthForItemAtIndex :1;
    }_delegateFlags;
    DQTabPageBarLayout *_layout;
}

// UI
@property (nonatomic, weak) UICollectionView *collectionView;
// Data
@property (nonatomic, assign) NSInteger countOfItems;

@property (nonatomic, assign) NSInteger curIndex;

@property (nonatomic, assign) BOOL isFirstLayout;

@property (nonatomic, assign) BOOL didLayoutSubViews;

@end


@implementation DQTabPageBar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _isFirstLayout = YES;
        _didLayoutSubViews = NO;
        _autoScrollItemToCenter = YES;
        self.backgroundColor = [UIColor whiteColor];
        [self addFixAutoAdjustInsetScrollView];
        [self addCollectionView];
        [self addUnderLineView];
        [self addBottomLineView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _isFirstLayout = YES;
        _didLayoutSubViews = NO;
        _autoScrollItemToCenter = YES;
        self.backgroundColor = [UIColor clearColor];
        [self addFixAutoAdjustInsetScrollView];
        [self addCollectionView];
        [self addUnderLineView];
        [self addBottomLineView];
    
    }
    return self;
}

- (void)addFixAutoAdjustInsetScrollView {
    UIView *view = [[UIView alloc]init];
    [self addSubview:view];
}

- (void)addCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *collectionView = [[UICollectionView alloc]initWithFrame:UIEdgeInsetsInsetRect(self.bounds, _contentInset) collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor clearColor];
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.showsVerticalScrollIndicator = NO;
    
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [self addSubview:collectionView];
    _collectionView = collectionView;
}

- (void)addUnderLineView {
    UIView *progressView = [[UIView alloc]init];
    progressView.backgroundColor = [UIColor colorWithRed:100.0f/255.0f green:147.0f/255.0f blue:254.0f/255.0f alpha:1.0f];
    [_collectionView addSubview:progressView];
    _progressView = progressView;
}

- (void)addBottomLineView {
    UIView * bottomLine = [[UIView alloc] init];
    bottomLine.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:1.0f];
    [self addSubview:bottomLine];
    _bottomLineView = bottomLine;
}

#pragma mark - getter/setter

- (void)setProgressView:(UIView *)progressView {
    if (_progressView == progressView) {
        return;
    }
    if (_progressView) {
        [_progressView removeFromSuperview];
    }
    if (_layout && _layout.barStyle == DQPageBarStyleCoverView) {
        progressView.layer.zPosition = -1;
        [_collectionView insertSubview: progressView atIndex:0];
    }else {
        [_collectionView addSubview:progressView];
    }
    if (_layout && self.superview) {
        [_layout layoutSubViews];
    }
}

- (void)setBackgroundView:(UIView *)backgroundView {
    if (_backgroundView) {
        [_backgroundView removeFromSuperview];
    }
    _backgroundView = backgroundView;
    backgroundView.frame = self.bounds;
    [self insertSubview:backgroundView atIndex:0];
}

- (void)setDelegate:(id<DQTabPageBarDelegate>)delegate {
    _delegate = delegate;
    _delegateFlags.transitionFromeCellAnimated = [delegate respondsToSelector:@selector(pageTabBar:transitionFromeCell:toCell:animated:)];
    _delegateFlags.transitionFromeCellProgress = [delegate respondsToSelector:@selector(pageTabBar:transitionFromeCell:toCell:progress:)];
    _delegateFlags.widthForItemAtIndex = [delegate respondsToSelector:@selector(pageTabBar:widthForItemAtIndex:)];
    _delegateFlags.didSelectItemAtIndex = [delegate respondsToSelector:@selector(pageTabBar:didSelectItemAtIndex:)];
}

- (void)setLayout:(DQTabPageBarLayout *)layout {
    BOOL updateLayout = _layout && _layout != layout;
    _layout = layout;
    if (updateLayout) {
        [self reloadData];
    }
}

- (DQTabPageBarLayout *)layout {
    if (!_layout) {
        _layout = [[DQTabPageBarLayout alloc] initWithPagerTabBar:self];
    }
    return _layout;
}

#pragma mark - public

- (void)reloadData {
    _countOfItems = [_dataSource numberOfItemsInPageTabBar];
    if (_curIndex >= _countOfItems) {
        _curIndex = _countOfItems - 1;
    }
    if ([_delegate respondsToSelector:@selector(pagerTabBar:configureLayout:)]) {
        [_delegate pageTabBar:self configureLayout:self.layout];
    }
    [self.layout layoutIfNeed];
    [_collectionView reloadData];
    [self.layout adjustContentCellsCenterInBar];
    [self.layout layoutSubViews];
}

- (void)registerClass:(Class)Class forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerClass:Class forCellWithReuseIdentifier:identifier];
}

- (void)registerNib:(UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier {
    [_collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}

- (__kindof UICollectionViewCell<DQTabPageBarCellProtocol> *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    UICollectionViewCell<DQTabPageBarCellProtocol> *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    return cell;
}

- (CGRect)cellFrameWithIndex:(NSInteger)index {
    if (index >= _countOfItems) {
        return CGRectZero;
    }
    UICollectionViewLayoutAttributes * cellAttrs = [_collectionView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    if (!cellAttrs) {
        return CGRectZero;
    }
    return cellAttrs.frame;
}

- (UICollectionViewCell<DQTabPageBarCellProtocol> *)cellForIndex:(NSInteger)index {
    if (index >= _countOfItems) {
        return nil;
    }
    return (UICollectionViewCell<DQTabPageBarCellProtocol> *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}

- (void)scrollToItemFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex animate:(BOOL)animate {
    if (toIndex < _countOfItems && toIndex >= 0 && fromIndex < _countOfItems && fromIndex >= 0) {
        _curIndex = toIndex;
        [self transitionFromIndex:fromIndex toIndex:toIndex animated:animate];
        if (_autoScrollItemToCenter) {
            if (!_didLayoutSubViews) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self scrollToItemAtIndex:toIndex atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animate];
                });
            }else {
                [self scrollToItemAtIndex:toIndex atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animate];
            }
        }
    }
}

- (void)scrollToItemFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress {
    if (toIndex < _countOfItems && toIndex >= 0 && fromIndex < _countOfItems && fromIndex >= 0) {
        [self transitionFromIndex:fromIndex toIndex:toIndex progress:progress];
    }
}

- (void)scrollToItemAtIndex:(NSInteger)index atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated {
    [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:scrollPosition animated:animated];
}

- (CGFloat)cellWidthForTitle:(NSString *)title {
    if (!title) {
        return CGSizeZero.width;
    }
    //iOS 7
    CGRect frame = [title boundingRectWithSize:CGSizeMake(1000, 1000) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{ NSFontAttributeName:self.layout.selectedTextFont} context:nil];
    return CGSizeMake(ceil(frame.size.width), ceil(frame.size.height) + 1).width;
}

#pragma mark - UICollectionViewDataSource

/** 1.返回item的总数 */
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    _countOfItems = [_dataSource numberOfItemsInPageTabBar];
    return _countOfItems;
}

/** 3.返回item*/
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell<DQTabPageBarCellProtocol> *cell = [_dataSource pageTabBar:self cellForItemAtIndex:indexPath.item];
    [self.layout transitionFromCell:(indexPath.item == _curIndex ? nil : cell) toCell:(indexPath.item == _curIndex ? cell : nil) animate:NO];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(pageTabBar:didSelectItemAtIndex:)]) {
        [_delegate pageTabBar:self didSelectItemAtIndex:indexPath.item];
    }
}
/** 2.返回item的尺寸 */
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.layout.cellWidth > 0) {
        return CGSizeMake(self.layout.cellWidth+self.layout.cellEdging*2, CGRectGetHeight(_collectionView.frame));
    }else if(_delegateFlags.widthForItemAtIndex){
        CGFloat width = [_delegate pageTabBar:self widthForItemAtIndex:indexPath.item]+self.layout.cellEdging*2;
        return CGSizeMake(width, CGRectGetHeight(_collectionView.frame));
    }else {
        NSAssert(NO, @"you must return cell width!");
    }
    return CGSizeZero;
}

#pragma mark - transition cell

- (void)transitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex animated:(BOOL)animated {
    UICollectionViewCell<DQTabPageBarCellProtocol> *fromCell = [self cellForIndex:fromIndex];
    UICollectionViewCell<DQTabPageBarCellProtocol> *toCell = [self cellForIndex:toIndex];
    if (_delegateFlags.transitionFromeCellAnimated) {
        [_delegate pageTabBar:self transitionFromeCell:fromCell toCell:toCell animated:animated];
    }else {
        [self.layout transitionFromCell:fromCell toCell:toCell animate:animated];
    }
    [self.layout setUnderLineFrameWithIndex:toIndex animated:fromCell && animated ? animated: NO];
}

- (void)transitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress {
    UICollectionViewCell<DQTabPageBarCellProtocol> *fromCell = [self cellForIndex:fromIndex];
    UICollectionViewCell<DQTabPageBarCellProtocol> *toCell = [self cellForIndex:toIndex];
    if (_delegateFlags.transitionFromeCellProgress) {
        [_delegate pageTabBar:self transitionFromeCell:fromCell toCell:toCell progress:progress];
    }else {
        [self.layout transitionFromCell:fromCell toCell:toCell progress:progress];
    }
    [self.layout setUnderLineFrameWithfromIndex:fromIndex toIndex:toIndex progress:progress];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _backgroundView.frame = self.bounds;
    CGRect frame = UIEdgeInsetsInsetRect(self.bounds, _contentInset);
    BOOL needUpdateLayout = (frame.size.height > 0 && _collectionView.frame.size.height != frame.size.height) || (frame.size.width > 0 && _collectionView.frame.size.width != frame.size.width);
    _collectionView.frame = frame;
    if (!_didLayoutSubViews && !CGRectIsEmpty(_collectionView.frame)) {
        _didLayoutSubViews = YES;
    }
    if (needUpdateLayout) {
        [_layout invalidateLayout];
    }
    if (frame.size.height > 0 && frame.size.width > 0) {
        [_layout adjustContentCellsCenterInBar];
    }
    _bottomLineView.frame = CGRectMake(0, CGRectGetHeight(self.frame) - 1, CGRectGetWidth(self.frame), 1);
    
    _isFirstLayout = NO;
    [_layout layoutSubViews];
}

- (void)dealloc {
    _collectionView.dataSource = nil;
    _collectionView.delegate = nil;
}


@end
