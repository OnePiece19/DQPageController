//
//  DQViewController.m
//  DQPageController
//
//  Created by 381509610@qq.com on 05/08/2019.
//  Copyright (c) 2019 381509610@qq.com. All rights reserved.
//

#import "DQViewController.h"
#import "DQTabPageBar.h"
#import "DQPageController.h"

#define kScreenHeight   ([UIScreen mainScreen].bounds.size.height)
#define kScreenWidth    ([UIScreen mainScreen].bounds.size.width)

@interface DQViewController ()<DQTabPageBarDataSource,
                                DQTabPageBarDelegate,
                                DQPageControllerDataSource,
                                DQPageControllerDelegate>

@property (nonatomic, strong) NSArray * subControlArray;

@property (nonatomic, weak) DQTabPageBar *tabBar;

@property (nonatomic, weak) DQPageController *pageController;

@end

@implementation DQViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self addTabPageBar];
    [self addPageController];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
//    CGFloat navHeight = [TWUtil getNavigationBarHeight];
    _tabBar.frame = CGRectMake(0,88, kScreenWidth, 44);
    CGFloat pageControllerH = CGRectGetHeight(self.view.frame)- CGRectGetMaxY(_tabBar.frame);
    _pageController.view.frame = CGRectMake(0, CGRectGetMaxY(_tabBar.frame), CGRectGetWidth(self.view.frame), pageControllerH);
}

- (void)addTabPageBar {
    DQTabPageBar * tabBar = [[DQTabPageBar alloc] init];
    tabBar.layout.barStyle = DQPageBarStyleProgressElasticView;
    tabBar.layout.progressRadius = 2.0f;
    tabBar.layout.progressHeight = 4.0f;
    tabBar.layout.progressVerEdging = 1.0f;
    tabBar.dataSource = self;
    tabBar.delegate = self;
    [tabBar registerClass:[DQTabPageBarCell class] forCellWithReuseIdentifier:[DQTabPageBarCell cellIdentifier]];
    [self.view addSubview:tabBar];
    [tabBar reloadData];
    _tabBar = tabBar;
}

- (void)addPageController {
    DQPageController * pageController = [[DQPageController alloc] init];
    pageController.dataSource = self;
    pageController.delegate = self;
    [self addChildViewController:pageController];
    [self.view addSubview:pageController.view];
    _pageController = pageController;
}

#pragma mark - DQTabPageBarDataSource  and  DQTabPageBarDelegate
- (NSInteger)numberOfItemsInPageTabBar {
    return self.subControlArray.count;
}

- (UICollectionViewCell<DQTabPageBarCellProtocol> *)pageTabBar:(DQTabPageBar *)pageTabBar cellForItemAtIndex:(NSInteger)index {
    UICollectionViewCell<DQTabPageBarCellProtocol> *cell = [pageTabBar dequeueReusableCellWithReuseIdentifier:
                                                            [DQTabPageBarCell cellIdentifier] forIndex:index];
    NSDictionary * controlDict = self.subControlArray[index];
    cell.titleLabel.text = controlDict[@"tabName"];
    return cell;
}

- (CGFloat)pageTabBar:(DQTabPageBar *)pageTabBar widthForItemAtIndex:(NSInteger)index {
    NSDictionary * controlDict = self.subControlArray[index];
    return [pageTabBar cellWidthForTitle:controlDict[@"tabName"]];
}

- (void)pageTabBar:(DQTabPageBar *)pageTabBar didSelectItemAtIndex:(NSInteger)index {
    [_pageController scrollToItemAtIndex:index animate:YES];
}

#pragma mark - DQPageControllerDataSource and delegate

- (NSInteger)numberOfControllersInpageController {
    return self.subControlArray.count;
}

- (UIViewController *)pageController:(DQPageController *)pageController controllerForIndex:(NSInteger)index prefetching:(BOOL)prefetching {
    NSDictionary * controlDict = self.subControlArray[index];
    UIViewController * subController = [[NSClassFromString(controlDict[@"className"]) alloc] init];
    return subController;
}

- (void)pageController:(DQPageController *)pageController transitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex animated:(BOOL)animated {
    [_tabBar scrollToItemFromIndex:fromIndex toIndex:toIndex animate:YES];
}

- (void)pageController:(DQPageController *)pageController transitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress {
    [_tabBar scrollToItemFromIndex:fromIndex toIndex:toIndex progress:progress];
}

#pragma mark - 懒加载

- (NSArray *)subControlArray {
    if (!_subControlArray) {
        
        _subControlArray = @[@{@"className":@"UIViewController",
                               @"tabName":@"标题一"},
                             @{@"className":@"UIViewController",
                               @"tabName":@"标题二"},
                             @{@"className":@"UIViewController",
                               @"tabName":@"标题三"}];
    }
    return _subControlArray;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
