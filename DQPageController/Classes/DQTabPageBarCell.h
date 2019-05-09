//
//  DQTabPageBarCell.h
//  WXQuestion
//
//  Created by HX on 2019/3/18.
//  Copyright © 2019 中公网校. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DQTabPageBarCellProtocol <NSObject>

@property (nonatomic, strong, readonly) UILabel *titleLabel;

@end

@interface DQTabPageBarCell : UICollectionViewCell

@property (nonatomic, weak,readonly) UILabel *titleLabel;

+ (NSString *)cellIdentifier;

@end

NS_ASSUME_NONNULL_END
