//
//  DQTabPageBarCell.m
//  WXQuestion
//
//  Created by HX on 2019/3/18.
//  Copyright © 2019 中公网校. All rights reserved.
//

#import "DQTabPageBarCell.h"

@interface DQTabPageBarCell ()

@property (nonatomic, weak) UILabel *titleLabel;

@end

@implementation DQTabPageBarCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self addTabTitleLabel];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self addTabTitleLabel];
    }
    return self;
}

- (void)addTabTitleLabel
{
    UILabel *titleLabel = [[UILabel alloc]init];
    titleLabel.font = [UIFont systemFontOfSize:15];
    titleLabel.textColor = [UIColor darkTextColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:titleLabel];
    _titleLabel = titleLabel;
}

+ (NSString *)cellIdentifier {
    return @"DQTabPagerBarCell";
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _titleLabel.frame = self.contentView.bounds;
}


@end
