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

@property (nonatomic, strong) NSMutableArray * subControlArray;

@property (nonatomic, weak) DQTabPageBar *tabBar;

@property (nonatomic, weak) DQPageController *pageController;

@end

@implementation DQViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self.subControlArray addObject:@{@"className":@"UIViewController",
                                  @"tabName":@"标题一"}];
    [self.subControlArray addObject:@{@"className":@"UIViewController",
                                  @"tabName":@"标题二"}];
    [self.subControlArray addObject:@{@"className":@"UIViewController",
                                  @"tabName":@"标题三"}];
    [self.subControlArray addObject:@{@"className":@"UIViewController",
                                  @"tabName":@"标题四"}];
    [self.subControlArray addObject:@{@"className":@"UIViewController",
                                  @"tabName":@"标题五"}];
    [self addNavRightBtn];
    [self addTabPageBar];
    [self addPageController];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat safetop = 0;
    if (@available(iOS 11.0, *)) {
        safetop = [UIApplication sharedApplication].delegate.window.safeAreaInsets.top;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    _tabBar.frame = CGRectMake(0, safetop+44, kScreenWidth, 44);
    
    CGFloat pageControllerH = CGRectGetHeight(self.view.frame)- CGRectGetMaxY(_tabBar.frame);
    _pageController.view.frame = CGRectMake(0, CGRectGetMaxY(_tabBar.frame), CGRectGetWidth(self.view.frame), pageControllerH);
}

- (void)addNavRightBtn {
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 30, 30);
    [btn setTitle:@"reload" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(reloadDataSource) forControlEvents:UIControlEventTouchUpInside];
    btn.titleLabel.font = [UIFont systemFontOfSize:16.0f];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn sizeToFit];
    UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)addTabPageBar {
    DQTabPageBar * tabBar = [[DQTabPageBar alloc] init];
    tabBar.layout.barStyle = DQPageBarStyleProgressElasticView;
    tabBar.layout.progressRadius = 2.0f;
    tabBar.layout.progressHeight = 4.0f;
    tabBar.layout.progressVerEdging = 1.0f;
    /*
     字号更改时，无法添加动画，通过修改比例 显示动画
     */
    tabBar.layout.normalTextFont = [UIFont systemFontOfSize:15.0];
    tabBar.layout.selectedTextFont = [UIFont systemFontOfSize:15.0];
    tabBar.layout.selectFontScale = 15.0f/17.0f; // 设定同比字号缩放
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
    /*
     单页也可以横向滑动设置
     */
    pageController.scrollView.alwaysBounceHorizontal = YES;
}

- (void)reloadDataSource {
    [self.subControlArray removeLastObject];
    [self.tabBar reloadData];
    [self.pageController reloadData];
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

#pragma mark - DQPageControllerDataSource

- (NSInteger)numberOfControllersInpageController {
    return self.subControlArray.count;
}

- (UIViewController *)pageController:(DQPageController *)pageController controllerForIndex:(NSInteger)index prefetching:(BOOL)prefetching {
    NSDictionary * controlDict = self.subControlArray[index];
    UIViewController * subController = [[NSClassFromString(controlDict[@"className"]) alloc] init];
    subController.view.backgroundColor = ([UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0f]);
    return subController;
}

#pragma mark - DQPageControllerDelegate

- (void)pageController:(DQPageController *)pageController viewWillAppear:(UIViewController *)viewController forIndex:(NSInteger)index {
    NSLog(@"将要显示 %ld",(long)index);
}

- (void)pageController:(DQPageController *)pageController viewDidAppear:(UIViewController *)viewController forIndex:(NSInteger)index {
    NSLog(@"已经显示 %ld",(long)index);
}

- (void)pageController:(DQPageController *)pageController viewWillDisappear:(UIViewController *)viewController forIndex:(NSInteger)index {
    NSLog(@"将要消失 %ld",(long)index);
}

- (void)pageController:(DQPageController *)pageController viewDidDisappear:(UIViewController *)viewController forIndex:(NSInteger)index {
    NSLog(@"已经消失 %ld",(long)index);
}

- (void)pageController:(DQPageController *)pageController transitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex animated:(BOOL)animated {
    [_tabBar scrollToItemFromIndex:fromIndex toIndex:toIndex animate:YES];
}

- (void)pageController:(DQPageController *)pageController transitionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress {
    [_tabBar scrollToItemFromIndex:fromIndex toIndex:toIndex progress:progress];
}

#pragma mark - 懒加载

- (NSMutableArray *)subControlArray {
    if (!_subControlArray) {
        _subControlArray = [NSMutableArray array];
    }
    return _subControlArray;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
